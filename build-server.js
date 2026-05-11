// ════════════════════════════════════════════════════════════════════════════════
// APK Build Server - Node.js/Express Backend
// Generates real Flutter projects from designer config and builds APKs
// VERSION: 5
// ════════════════════════════════════════════════════════════════════════════════
const SERVER_VERSION = 6;

const express = require('express');
const fs = require('fs-extra');
const path = require('path');
const { exec } = require('child_process');
const { v4: uuidv4 } = require('uuid');
const bodyParser = require('body-parser');
const cors = require('cors');
const os = require('os');

const app = express();
const PORT = 3001;

app.use(cors({ origin: '*', methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'], allowedHeaders: ['Content-Type', 'Authorization', 'Accept'], credentials: false }));
app.options('*', cors());
app.use((req, res, next) => { res.header('Access-Control-Allow-Origin', '*'); res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS'); res.header('Access-Control-Allow-Headers', 'Content-Type'); next(); });
app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ limit: '50mb', extended: true }));

const BUILDS_DIR = path.join(__dirname, 'builds');
const PROJECTS_DIR = path.join(__dirname, 'projects');
const APKS_DIR = path.join(__dirname, 'apks');
const TEMP_DIR = path.join(__dirname, 'temp');
[BUILDS_DIR, PROJECTS_DIR, APKS_DIR, TEMP_DIR].forEach(dir => fs.ensureDirSync(dir));

const buildStates = new Map();

// ════════════════════════════════════════════════════════════════════════════════
// API Routes
// ════════════════════════════════════════════════════════════════════════════════

app.get('/health', (req, res) => res.json({ status: 'running', version: SERVER_VERSION }));

app.post('/api/build/submit', async (req, res) => {
    try {
        const appConfig = req.body;
        const host = req.get('host');
        const serverIp = host ? host.split(':')[0] : '127.0.0.1';
        const buildId = uuidv4();
        const buildDir = path.join(BUILDS_DIR, buildId);

        if (!appConfig.id || !appConfig.name) return res.status(400).json({ error: 'Missing app id or name' });

        appConfig.serverIp = serverIp;

        const buildRecord = {
            id: buildId, appId: appConfig.id, appName: appConfig.name,
            status: 'pending', progress: 0, startTime: Date.now(), endTime: null,
            logs: ['📋 Build queued'], downloadUrl: null, error: null,
        };
        buildStates.set(buildId, buildRecord);

        fs.ensureDirSync(buildDir);
        fs.writeJsonSync(path.join(buildDir, 'config.json'), appConfig);

        startBuildProcess(buildId, appConfig, buildDir).catch(err => console.error(`Background build error for ${buildId}:`, err));
        console.log(`✅ Build ${buildId} queued for ${appConfig.name}`);

        res.json({ buildId, status: 'pending', message: 'Build request accepted. Building in background...' });
    } catch (error) {
        console.error('Build submission error:', error);
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/build/status/:buildId', (req, res) => {
    try {
        const { buildId } = req.params;
        const buildRecord = buildStates.get(buildId);
        if (!buildRecord) return res.status(404).json({ error: 'Build not found' });
        res.json({
            buildId, status: buildRecord.status, progress: buildRecord.progress,
            logs: buildRecord.logs, downloadUrl: buildRecord.downloadUrl, error: buildRecord.error,
            elapsedTime: buildRecord.endTime ? buildRecord.endTime - buildRecord.startTime : Date.now() - buildRecord.startTime,
        });
    } catch (error) { res.status(500).json({ error: error.message }); }
});

app.post('/api/build/cancel/:buildId', (req, res) => {
    try {
        const { buildId } = req.params;
        const buildRecord = buildStates.get(buildId);
        if (!buildRecord) return res.status(404).json({ error: 'Build not found' });
        if (buildRecord.status === 'complete' || buildRecord.status === 'failed') return res.status(400).json({ error: 'Build already finished' });
        buildRecord.status = 'failed';
        buildRecord.logs.push('⛔ Build cancelled by user');
        res.json({ message: 'Build cancelled' });
    } catch (error) { res.status(500).json({ error: error.message }); }
});

app.get('/api/build/logs/:buildId', (req, res) => {
    const buildRecord = buildStates.get(req.params.buildId);
    if (!buildRecord) return res.status(404).json({ error: 'Build not found' });
    res.json({ logs: buildRecord.logs });
});

app.get('/api/download/:buildId', (req, res) => {
    try {
        const { buildId } = req.params;
        const buildRecord = buildStates.get(buildId);
        if (!buildRecord) return res.status(404).json({ error: 'Build not found' });
        if (buildRecord.status !== 'complete') return res.status(400).json({ error: `Build not completed. Status: ${buildRecord.status}`, status: buildRecord.status });

        const apkPath = path.join(APKS_DIR, `${buildId}.apk`);
        if (!fs.existsSync(apkPath)) return res.status(404).json({ error: 'APK file not found' });

        const stats = fs.statSync(apkPath);
        res.setHeader('Content-Type', 'application/vnd.android.package-archive');
        res.setHeader('Content-Disposition', 'attachment; filename="app-release.apk"');
        res.setHeader('Content-Length', stats.size);
        res.setHeader('Access-Control-Allow-Origin', '*');

        const fileStream = fs.createReadStream(apkPath);
        fileStream.pipe(res);
        fileStream.on('error', err => { if (!res.headersSent) res.status(500).json({ error: 'Download failed' }); });
        console.log(`📥 APK ${buildId} downloaded (${formatFileSize(stats.size)})`);
    } catch (error) { res.status(500).json({ error: error.message }); }
});

// ════════════════════════════════════════════════════════════════════════════════
// Build Process
// ════════════════════════════════════════════════════════════════════════════════

async function startBuildProcess(buildId, appConfig, buildDir) {
    const buildRecord = buildStates.get(buildId);
    try {
        buildRecord.logs.push('🚀 Starting APK build process...');
        buildRecord.status = 'building';
        updateProgress(buildId, 5);

        buildRecord.logs.push('📝 Generating Flutter project...');
        await generateFlutterProject(buildId, appConfig, buildDir);
        updateProgress(buildId, 20);
        buildRecord.logs.push('✅ Flutter project generated');

        buildRecord.logs.push('📦 Installing dependencies (flutter pub get)...');
        await installDependencies(buildId, buildDir);
        updateProgress(buildId, 40);
        buildRecord.logs.push('✅ Dependencies installed');

        buildRecord.logs.push('🔨 Building APK (flutter build apk --release)...');
        await buildApk(buildId, buildDir);
        updateProgress(buildId, 85);
        buildRecord.logs.push('✅ APK compilation completed');

        buildRecord.logs.push('✔️ Validating APK file...');
        const apkPath = await validateApkExists(buildId, buildDir);
        updateProgress(buildId, 95);
        buildRecord.logs.push(`✅ APK validated (${formatFileSize(fs.statSync(apkPath).size)})`);

        buildRecord.logs.push('💾 Moving APK to storage...');
        await moveApkToStorage(buildId, buildDir, apkPath);
        updateProgress(buildId, 99);

        const downloadUrl = `http://${appConfig.serverIp}:${PORT}/api/download/${buildId}`;
        buildRecord.status = 'complete';
        buildRecord.progress = 100;
        buildRecord.downloadUrl = downloadUrl;
        buildRecord.endTime = Date.now();
        buildRecord.logs.push('✅ Build completed successfully!');
        buildRecord.logs.push(`📥 Download URL: ${downloadUrl}`);
        console.log(`✅ Build ${buildId} completed successfully`);
    } catch (error) {
        console.error(`❌ Build ${buildId} failed:`, error);
        buildRecord.status = 'failed';
        buildRecord.error = error.message;
        buildRecord.endTime = Date.now();
        buildRecord.logs.push(`❌ BUILD FAILED: ${error.message}`);
        buildRecord.logs.push('💡 Check backend console for details. Ensure Flutter SDK and Android SDK are configured.');
    }
}

async function installDependencies(buildId, buildDir) {
    const projectDir = path.join(buildDir, 'flutter_app');
    const buildRecord = buildStates.get(buildId);
    return new Promise((resolve, reject) => {
        exec(`cd "${projectDir}" && flutter pub get`, { maxBuffer: 10 * 1024 * 1024, shell: true }, (error, stdout, stderr) => {
            if (error) { const msg = stderr || stdout || error.message; buildRecord.logs.push(msg); reject(new Error(`Dependency installation failed: ${msg}`)); }
            else resolve();
        });
    });
}

async function buildApk(buildId, buildDir) {
    const projectDir = path.join(buildDir, 'flutter_app');
    const buildRecord = buildStates.get(buildId);
    return new Promise((resolve, reject) => {
        exec(`cd "${projectDir}" && flutter build apk --release 2>&1`, { maxBuffer: 50 * 1024 * 1024, timeout: 30 * 60 * 1000, shell: true }, (error, stdout, stderr) => {
            if (error) {
                const fullOutput = (stdout || '') + (stderr || '');
                fullOutput.split('\n').forEach(line => { if (line.trim()) buildRecord.logs.push(line); });
                reject(new Error(`APK build failed: ${stderr || stdout || error.message}`));
            } else resolve();
        });
    });
}

async function validateApkExists(buildId, buildDir) {
    // Check both the redirected path (after build.gradle fix) and the fallback
    const candidates = [
        path.join(buildDir, 'flutter_app', 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk'),
        path.join(buildDir, 'flutter_app', 'android', 'app', 'build', 'outputs', 'flutter-apk', 'app-release.apk'),
        path.join(buildDir, 'flutter_app', 'android', 'app', 'build', 'outputs', 'apk', 'release', 'app-release.apk'),
    ];
    for (const candidate of candidates) {
        if (fs.existsSync(candidate) && fs.statSync(candidate).size > 0) {
            console.log(`[build] APK found at: ${candidate}`);
            return candidate;
        }
    }
    throw new Error(`APK not found. Checked:\n${candidates.join('\n')}`);
}

async function moveApkToStorage(buildId, buildDir, apkSource) {
    const apkDest = path.join(APKS_DIR, `${buildId}.apk`);
    await fs.copy(apkSource, apkDest);
    if (!fs.existsSync(apkDest) || fs.statSync(apkDest).size <= 0) throw new Error('APK copy failed');
    return apkDest;
}

function updateProgress(buildId, progress) {
    const buildRecord = buildStates.get(buildId);
    if (buildRecord) buildRecord.progress = Math.min(progress, 99);
}

function formatFileSize(bytes) { return `${(bytes / 1024 / 1024).toFixed(2)} MB`; }

// ════════════════════════════════════════════════════════════════════════════════
// Flutter Project Generation
// ════════════════════════════════════════════════════════════════════════════════

async function generateFlutterProject(buildId, appConfig, buildDir) {
    const projectDir = path.join(buildDir, 'flutter_app');
    fs.ensureDirSync(projectDir);

    // Host project paths (for copying shared resources)
    const hostAndroidDir = path.join(__dirname, '..', 'android');

    // Use the package name already registered in google-services.json so Firebase
    // doesn't throw "No matching client found for package name".
    let packageName = sanitizePackageName(appConfig.name);
    const hostGoogleServicesPath = path.join(hostAndroidDir, 'app', 'google-services.json');
    if (fs.existsSync(hostGoogleServicesPath)) {
        try {
            const gsJson = fs.readJsonSync(hostGoogleServicesPath);
            const registeredPkg = (gsJson.client || [])[0]
                ?.client_info?.android_client_info?.package_name;
            if (registeredPkg) packageName = registeredPkg;
        } catch (e) {
            console.warn('Could not read package name from google-services.json:', e.message);
        }
    }

    // lib/main.dart
    fs.ensureDirSync(path.join(projectDir, 'lib'));
    fs.writeFileSync(path.join(projectDir, 'lib', 'main.dart'), generateMainDart(appConfig));

    // pubspec.yaml
    fs.writeFileSync(path.join(projectDir, 'pubspec.yaml'), generatePubspec(appConfig));

    // .gitignore
    fs.writeFileSync(path.join(projectDir, '.gitignore'), generateGitignore());

    // Android directory
    fs.ensureDirSync(path.join(projectDir, 'android'));

    // gradle.properties
    fs.writeFileSync(path.join(projectDir, 'android', 'gradle.properties'), generateGradleProperties());

    // settings.gradle.kts
    fs.writeFileSync(path.join(projectDir, 'android', 'settings.gradle.kts'), generateSettingsGradleKts());

    // build.gradle.kts (project level)
    fs.writeFileSync(path.join(projectDir, 'android', 'build.gradle.kts'), generateProjectBuildGradleKts());

    // app/build.gradle.kts
    fs.ensureDirSync(path.join(projectDir, 'android', 'app'));
    fs.writeFileSync(path.join(projectDir, 'android', 'app', 'build.gradle.kts'), generateAppBuildGradleKts(packageName));

    // AndroidManifest.xml
    fs.ensureDirSync(path.join(projectDir, 'android', 'app', 'src', 'main'));
    fs.writeFileSync(path.join(projectDir, 'android', 'app', 'src', 'main', 'AndroidManifest.xml'), generateAndroidManifest(appConfig, packageName));

    // MainActivity.kt
    const kotlinParts = packageName.split('.');
    const kotlinDir = path.join(projectDir, 'android', 'app', 'src', 'main', 'kotlin', ...kotlinParts);
    fs.ensureDirSync(kotlinDir);
    fs.writeFileSync(path.join(kotlinDir, 'MainActivity.kt'), generateMainActivityKt(packageName));

    // Android resources — only what the build strictly needs.
    // No @mipmap/ic_launcher in the manifest, so no PNG files required.
    const resDir = path.join(projectDir, 'android', 'app', 'src', 'main', 'res');
    fs.ensureDirSync(path.join(resDir, 'values'));
    fs.ensureDirSync(path.join(resDir, 'drawable'));
    fs.writeFileSync(path.join(resDir, 'values', 'styles.xml'), generateStylesXml());
    fs.writeFileSync(path.join(resDir, 'values', 'colors.xml'), generateColorsXml());
    fs.writeFileSync(path.join(resDir, 'drawable', 'launch_background.xml'), generateLaunchBackgroundXml());

    // local.properties — copy from host (has real flutter.sdk and sdk.dir paths)
    const hostLocalProps = path.join(hostAndroidDir, 'local.properties');
    if (fs.existsSync(hostLocalProps)) {
        // Copy but strip flutter.buildMode line so release build works
        const contents = fs.readFileSync(hostLocalProps, 'utf8')
            .split('\n')
            .filter(line => !line.startsWith('flutter.buildMode'))
            .join('\n');
        fs.writeFileSync(path.join(projectDir, 'android', 'local.properties'), contents);
    }

    // google-services.json — copy from host Firebase project (package name already matched above)
    if (fs.existsSync(hostGoogleServicesPath)) {
        fs.copySync(hostGoogleServicesPath, path.join(projectDir, 'android', 'app', 'google-services.json'));
    }

    // Gradle wrapper — copy from host (binary jar + properties + scripts)
    const hostWrapperDir = path.join(hostAndroidDir, 'gradle', 'wrapper');
    const genWrapperDir = path.join(projectDir, 'android', 'gradle', 'wrapper');
    fs.ensureDirSync(genWrapperDir);
    ['gradle-wrapper.jar', 'gradle-wrapper.properties'].forEach(f => {
        const src = path.join(hostWrapperDir, f);
        if (fs.existsSync(src)) fs.copySync(src, path.join(genWrapperDir, f));
    });
    ['gradlew', 'gradlew.bat'].forEach(f => {
        const src = path.join(hostAndroidDir, f);
        if (fs.existsSync(src)) fs.copySync(src, path.join(projectDir, 'android', f));
    });
}

// ════════════════════════════════════════════════════════════════════════════════
// Code Generation — main.dart (generates real UI from widget tree)
// ════════════════════════════════════════════════════════════════════════════════

function generateMainDart(appConfig) {
    const screens = appConfig.screens || [];
    const projectId = String(appConfig.id || 'project_id');
    const appName = String(appConfig.name || 'My App');
    const rawPrimaryColor = String((appConfig.theme || {}).primaryColor || '#00C896').replace(/^#/, '');

    // Escape a string for use inside a Dart single-quoted literal
    const esc = (s) => String(s || '').replace(/\\/g, '\\\\').replace(/'/g, "\\'").replace(/\n/g, '\\n').replace(/\r/g, '');

    // Convert hex color to Dart Color constructor
    const hexColor = (hex) => {
        const c = String(hex || '#000000').replace(/^#/, '').padEnd(6, '0').slice(0, 6);
        return `Color(0xFF${c.toUpperCase()})`;
    };

    // Make a safe Dart identifier from a widget ID
    const dartId = (s) => 'w' + String(s).replace(/[^a-zA-Z0-9]/g, '_');

    // Recursively collect all input widget IDs in a widget list
    function collectInputIds(widgets) {
        const ids = [];
        for (const w of (widgets || [])) {
            if (w.type === 'input') ids.push(w.id);
            ids.push(...collectInputIds(w.children));
        }
        return ids;
    }

    // Generate Dart code for a single widget
    function genWidget(w) {
        const p = w.properties || {};
        if (w.type === 'appbar' || w.type === 'navbar') return null;

        switch (w.type) {
            case 'text': {
                const content = esc(p.content || 'Text');
                const fontSize = Number(p.fontSize) || 16;
                const color = hexColor(p.color);
                const bold = p.bold ? 'FontWeight.bold' : 'FontWeight.normal';
                const alignMap = { left: 'TextAlign.left', center: 'TextAlign.center', right: 'TextAlign.right' };
                const align = alignMap[p.align] || 'TextAlign.left';
                return `Text('${content}', textAlign: ${align}, style: const TextStyle(fontSize: ${fontSize}, color: ${color}, fontWeight: ${bold}))`;
            }

            case 'button': {
                const label = esc(p.label || 'Button');
                const color = hexColor(p.color || '#00C896');
                const textColor = hexColor(p.textColor || '#FFFFFF');
                const radius = Number(p.borderRadius) || 12;
                const action = p.action || 'none';
                let onPressed = '() {}';
                if (action === 'addRecord') {
                    const table = esc(p.actionTable || '');
                    const fields = String(p.actionFields || '').split(',').map(f => f.trim()).filter(Boolean);
                    // Only wire up the dialog when a table has actually been selected.
                    // An empty table name would produce .collection('') which Firestore
                    // rejects with "A collectionPath must be a non-empty string".
                    if (table) {
                        const fieldsArr = '[' + fields.map(f => `'${esc(f)}'`).join(', ') + ']';
                        onPressed = `() => _showAddRecordDialog(context, '${table}', ${fieldsArr})`;
                    }
                }
                return `ElevatedButton(onPressed: ${onPressed}, style: ElevatedButton.styleFrom(backgroundColor: const ${color}, foregroundColor: const ${textColor}, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(${radius}))), child: const Text('${label}'))`;
            }

            case 'input': {
                const hint = esc(p.hint || '');
                const label = esc(p.label || '');
                const isPassword = p.type === 'password';
                const keyboard = isPassword ? 'TextInputType.visiblePassword' : p.type === 'number' ? 'TextInputType.number' : 'TextInputType.text';
                return `TextField(controller: _ctrl_${dartId(w.id)}, obscureText: ${isPassword}, keyboardType: ${keyboard}, decoration: const InputDecoration(hintText: '${hint}', labelText: '${label}', border: OutlineInputBorder()))`;
            }

            case 'image': {
                const src = esc(p.src || '');
                const radius = Number(p.borderRadius) || 0;
                const fitMap = { cover: 'BoxFit.cover', contain: 'BoxFit.contain', fill: 'BoxFit.fill' };
                const fit = fitMap[p.fit] || 'BoxFit.cover';
                if (!src) return `Container(height: 180, color: Colors.grey.shade200, child: const Icon(Icons.image, size: 48, color: Colors.grey))`;
                return `ClipRRect(borderRadius: BorderRadius.circular(${radius}), child: Image.network('${src}', fit: ${fit}, errorBuilder: (ctx, e, st) => const Icon(Icons.broken_image)))`;
            }

            case 'card': {
                const title = esc(p.title || 'Card Title');
                const subtitle = esc(p.subtitle || '');
                const titleColor = hexColor(p.titleColor || '#000000');
                const subtitleColor = hexColor(p.subtitleColor || '#666666');
                const sub = subtitle ? `, const SizedBox(height: 4), Text('${subtitle}', style: const TextStyle(color: ${subtitleColor}))` : '';
                return `Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${title}', style: const TextStyle(fontWeight: FontWeight.bold, color: ${titleColor}))${sub}])))`;
            }

            case 'divider': return `Divider(color: const ${hexColor(p.color || '#CCCCCC')}, thickness: ${Number(p.thickness) || 1})`;

            case 'icon': {
                const name = String(p.name || 'star').toLowerCase().replace(/[^a-z_0-9]/g, '_');
                return `Icon(Icons.${name}, color: const ${hexColor(p.color || '#FFD700')}, size: ${Number(p.size) || 40})`;
            }

            case 'circleavatar': {
                const imgUrl = esc(p.imageUrl || '');
                const radius = Number(p.radius) || 40;
                if (imgUrl) return `CircleAvatar(radius: ${radius}, backgroundImage: NetworkImage('${imgUrl}'))`;
                return `CircleAvatar(radius: ${radius}, backgroundColor: const ${hexColor(p.backgroundColor || '#00C896')}, child: Text('${esc(p.text || 'AB')}', style: const TextStyle(color: ${hexColor(p.textColor || '#FFFFFF')}, fontSize: ${Number(p.fontSize) || 18})))`;
            }

            case 'listtile': {
                const sub = esc(p.subtitle || '');
                const subCode = sub ? `subtitle: const Text('${sub}')` : '';
                return `ListTile(tileColor: const ${hexColor(p.backgroundColor || '#FFFFFF')}, title: Text('${esc(p.title || 'Item')}', style: const TextStyle(color: ${hexColor(p.textColor || '#000000')}))${subCode ? ', ' + subCode : ''})`;
            }

            case 'dropdown': {
                const hint = esc(p.hint || 'Select...');
                const options = String(p.options || '').split(',').map(o => o.trim()).filter(Boolean);
                const items = options.map(o => `DropdownMenuItem<String>(value: '${esc(o)}', child: Text('${esc(o)}'))`).join(', ');
                return `DropdownButtonFormField<String>(hint: const Text('${hint}'), items: [${items}], onChanged: (v) {}, decoration: const InputDecoration(border: OutlineInputBorder()))`;
            }

            case 'checkbox': return `_CheckboxWidget(label: '${esc(p.label || 'Check me')}', activeColor: const ${hexColor(p.color || '#00C896')})`;
            case 'switch_w': return `_SwitchWidget(label: '${esc(p.label || 'Toggle')}', activeColor: const ${hexColor(p.color || '#00C896')})`;

            case 'container': {
                const children = (w.children || []).map(genWidget).filter(Boolean);
                const child = children.length > 0 ? `Column(children: [${children.join(', ')}])` : 'const SizedBox()';
                return `Container(decoration: BoxDecoration(color: const ${hexColor(p.bgColor || p.color || '#E8E8E8')}, borderRadius: BorderRadius.circular(${Number(p.borderRadius) || 8}), border: Border.all(color: const ${hexColor(p.borderColor || '#CCCCCC')}, width: ${Number(p.borderWidth) || 1})), child: ${child})`;
            }

            case 'row': {
                const mainAxisMap = { start: 'MainAxisAlignment.start', center: 'MainAxisAlignment.center', end: 'MainAxisAlignment.end', spaceBetween: 'MainAxisAlignment.spaceBetween', spaceAround: 'MainAxisAlignment.spaceAround' };
                const mainAxis = mainAxisMap[p.mainAxisAlignment] || 'MainAxisAlignment.start';
                let children = (w.children || []).map(genWidget).filter(Boolean);
                const spacing = Number(p.spacing) || 0;
                if (spacing > 0) {
                    const spaced = [];
                    children.forEach((c, i) => { if (i > 0) spaced.push(`SizedBox(width: ${spacing})`); spaced.push(c); });
                    children = spaced;
                }
                return `Row(mainAxisAlignment: ${mainAxis}, children: [${children.join(', ')}])`;
            }

            case 'column': {
                const mainAxis = { start: 'MainAxisAlignment.start', center: 'MainAxisAlignment.center', end: 'MainAxisAlignment.end' }[p.mainAxisAlignment] || 'MainAxisAlignment.start';
                let children = (w.children || []).map(genWidget).filter(Boolean);
                const spacing = Number(p.spacing) || 0;
                if (spacing > 0) {
                    const spaced = [];
                    children.forEach((c, i) => { if (i > 0) spaced.push(`SizedBox(height: ${spacing})`); spaced.push(c); });
                    children = spaced;
                }
                return `Column(mainAxisAlignment: ${mainAxis}, crossAxisAlignment: CrossAxisAlignment.stretch, children: [${children.join(', ')}])`;
            }

            case 'list': {
                const items = String(p.items || '').split(',').map(i => i.trim()).filter(Boolean);
                const textColor = hexColor(p.textColor || '#000000');
                return `Column(children: [${items.map(item => `ListTile(dense: true, title: Text('${esc(item)}', style: const TextStyle(color: ${textColor})))`).join(', ')}])`;
            }

            case 'iconbtn': {
                const iconName = String(p.icon || 'favorite').toLowerCase().replace(/[^a-z_0-9]/g, '_');
                const bgColor = hexColor(p.color || '#00C896');
                const icColor = hexColor(p.iconColor || '#FFFFFF');
                const action = p.action || 'none';
                let onPressed = '() {}';
                if (action === 'addRecord') {
                    const table = esc(p.actionTable || '');
                    const fields = String(p.actionFields || '').split(',').map(f => f.trim()).filter(Boolean);
                    if (table) {
                        const fieldsArr = '[' + fields.map(f => `'${esc(f)}'`).join(', ') + ']';
                        onPressed = `() => _showAddRecordDialog(context, '${table}', ${fieldsArr})`;
                    }
                }
                return `IconButton(style: IconButton.styleFrom(backgroundColor: const ${bgColor}), icon: Icon(Icons.${iconName}, color: const ${icColor}), onPressed: ${onPressed})`;
            }

            case 'listview': {
                if (w.boundTable) {
                    const table = esc(w.boundTable);
                    const primaryC = hexColor('#' + rawPrimaryColor);
                    // Live Firestore stream with name/avatar ListTile layout
                    return `SizedBox(height: 300, child: StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('project_data').doc('${esc(projectId)}').collection('${table}').orderBy('createdAt', descending: true).snapshots(), builder: (ctx, snap) { if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator()); if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text('No records yet', style: const TextStyle(color: Colors.grey))); final docs = snap.data!.docs; return ListView.builder(itemCount: docs.length, shrinkWrap: true, itemBuilder: (ctx, i) { final data = Map<String, dynamic>.from(docs[i].data() as Map); data.remove('createdAt'); data.remove('id'); final allKeys = data.keys.toList(); final nameKey = allKeys.contains('name') ? 'name' : (allKeys.isNotEmpty ? allKeys.first : null); final titleVal = nameKey != null ? (data[nameKey]?.toString() ?? '') : ''; final subKeys = allKeys.where((k) => k != nameKey).take(2).toList(); final subtitleVal = subKeys.map((k) => data[k]?.toString() ?? '').where((v) => v.isNotEmpty).join(' · '); final letter = titleVal.isNotEmpty ? titleVal[0].toUpperCase() : '?'; return ListTile(leading: CircleAvatar(backgroundColor: const ${primaryC}, child: Text(letter, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))), title: Text(titleVal, style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: subtitleVal.isNotEmpty ? Text(subtitleVal, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)) : null); }); }))`;
                }
                const items = String(p.items || '').split(',').map(i => i.trim()).filter(Boolean);
                const textColor = hexColor(p.textColor || '#000000');
                return `Column(children: [${items.map(i => `ListTile(dense: true, title: Text('${esc(i)}', style: const TextStyle(color: ${textColor})))`).join(', ')}])`;
            }

            case 'singlechildscrollview': {
                const children = (w.children || []).map(genWidget).filter(Boolean);
                return `SingleChildScrollView(child: Column(children: [${children.join(', ')}]))`;
            }

            case 'form': {
                const fields = String(p.fields || '').split(',').map(f => f.trim()).filter(Boolean);
                const submitLabel = esc(p.submitLabel || 'Submit');
                const parts = fields.map(f => `TextFormField(decoration: const InputDecoration(labelText: '${esc(f)}', border: OutlineInputBorder()))`);
                parts.push(`ElevatedButton(onPressed: () {}, child: const Text('${submitLabel}'))`);
                return `Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [${parts.join(', const SizedBox(height: 12), ')}])`;
            }

            case 'grid': {
                const items = String(p.items || '').split(',').map(i => i.trim()).filter(Boolean);
                const crossAxisCount = Math.max(1, Math.round(Number(p.crossAxisCount || p.columns) || 2));
                const textColor = hexColor(p.textColor || '#000000');
                return `GridView.count(crossAxisCount: ${crossAxisCount}, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: [${items.map(item => `Card(child: Center(child: Text('${esc(item)}', style: const TextStyle(color: ${textColor}))))`).join(', ')}])`;
            }

            case 'chart': return `Container(height: 160, color: Colors.grey.shade100, child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.bar_chart, size: 48, color: Colors.grey), Text('Chart')])))`;

            case 'todo':
            case 'checkbox_todo': {
                const items = String(p.items || '').split(',').map(i => i.trim()).filter(Boolean);
                const color = hexColor(p.color || '#00C896');
                return `Column(children: [${items.map(item => `_CheckboxWidget(label: '${esc(item)}', activeColor: const ${color})`).join(', ')}])`;
            }

            case 'gesture_detector': {
                const label = esc(p.label || 'Tap me');
                const bg = hexColor(p.bgColor || '#00C896');
                const textColor = hexColor(p.textColor || '#FFFFFF');
                return `GestureDetector(onTap: () {}, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const ${bg}, borderRadius: BorderRadius.circular(${Number(p.borderRadius) || 8})), child: Center(child: Text('${label}', style: const TextStyle(color: ${textColor}, fontSize: ${Number(p.fontSize) || 14})))))`;
            }

            default: return `Container(height: 40, color: Colors.grey.shade200, child: Center(child: Text('${esc(w.type)}', style: const TextStyle(color: Colors.grey))))`;
        }
    }

    // Generate a StatefulWidget class for one screen
    function genScreen(screen, index) {
        const className = `AppScreen${index}`;
        const allWidgets = screen.widgets || [];

        const appbarWidget = allWidgets.find(w => w.type === 'appbar');
        const navbarWidget = allWidgets.find(w => w.type === 'navbar');
        const fabWidget    = allWidgets.find(w => w.type === 'fab');
        // FAB lives in Scaffold.floatingActionButton, not in body
        const bodyWidgets  = allWidgets.filter(w => w.type !== 'appbar' && w.type !== 'navbar' && w.type !== 'fab');

        const inputIds = collectInputIds(bodyWidgets);
        const controllerDecls = inputIds.map(id => `  final TextEditingController _ctrl_${dartId(id)} = TextEditingController();`).join('\n');
        const controllerDispose = inputIds.map(id => `    _ctrl_${dartId(id)}.dispose();`).join('\n');

        // AppBar — always present with search icon; uses widget props if placed, else falls back to defaults
        let appBarCode = '';
        {
            const ap = (appbarWidget || {}).properties || {};
            const bgC = hexColor(ap.color || '#' + rawPrimaryColor);
            const fgC = hexColor(ap.textColor || '#FFFFFF');
            const title = esc(ap.title || screen.name);
            appBarCode = `appBar: AppBar(title: Text('${title}'), backgroundColor: const ${bgC}, foregroundColor: const ${fgC}, actions: [IconButton(icon: const Icon(Icons.search), onPressed: () => Navigator.pushNamed(context, '/search'), tooltip: 'Search')]),`;
        }

        // BottomNavigationBar
        let bottomNavCode = '';
        const hasNavbar = !!navbarWidget;
        if (navbarWidget) {
            const np = navbarWidget.properties || {};
            const tabs = np.tabs || [];
            const iconMap = { home: 'home', search: 'search', person: 'person', settings: 'settings', favorite: 'favorite', star: 'star' };
            const items = tabs.map(t => `BottomNavigationBarItem(icon: Icon(Icons.${iconMap[t.icon] || 'circle'}), label: '${esc(t.label || '')}')`).join(', ');
            bottomNavCode = `bottomNavigationBar: BottomNavigationBar(currentIndex: _navIndex, onTap: (i) => setState(() => _navIndex = i), selectedItemColor: const ${hexColor(np.activeColor || '#00C896')}, unselectedItemColor: const ${hexColor(np.inactiveColor || '#999999')}, items: [${items}]),`;
        }

        // FAB — extracted to Scaffold.floatingActionButton
        let fabCode = '';
        if (fabWidget) {
            const fp = fabWidget.properties || {};
            const iconName = String(fp.icon || 'add').toLowerCase().replace(/[^a-z_0-9]/g, '_');
            const bgC = hexColor(fp.color || '#00C896');
            const action = fp.action || 'none';
            let onPressed = '() {}';
            if (action === 'addRecord') {
                const table = esc(fp.actionTable || '');
                const fields = String(fp.actionFields || '').split(',').map(f => f.trim()).filter(Boolean);
                if (table) {
                    const fieldsArr = '[' + fields.map(f => `'${esc(f)}'`).join(', ') + ']';
                    onPressed = `() => _showAddRecordDialog(context, '${table}', ${fieldsArr})`;
                }
            }
            fabCode = `floatingActionButton: FloatingActionButton(backgroundColor: const ${bgC}, onPressed: ${onPressed}, child: Icon(Icons.${iconName}, color: Colors.white)),`;
        }

        // Body widgets
        const widgetCodes = bodyWidgets
            .map(w => genWidget(w))
            .filter(Boolean)
            .map(code => `            Padding(padding: const EdgeInsets.only(bottom: 8), child: ${code})`);

        return `
class ${className} extends StatefulWidget {
  const ${className}({super.key});
  @override
  State<${className}> createState() => _${className}State();
}

class _${className}State extends State<${className}> {
${controllerDecls || '  // no input fields'}
${hasNavbar ? '  int _navIndex = 0;' : ''}

  @override
  void dispose() {
${controllerDispose || '    // nothing to dispose'}
    super.dispose();
  }

  void _showAddRecordDialog(BuildContext ctx, String table, List<String> fields) {
    // Guard: Firestore rejects empty collection paths immediately.
    if (table.trim().isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Button has no target table configured. Open the builder and set "Target Table" for this button.')),
      );
      return;
    }
    if (fields.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('No fields selected for this button. Open the builder and pick the fields to collect.')),
      );
      return;
    }
    final ctrl = <String, TextEditingController>{for (final f in fields) f: TextEditingController()};
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Add Record'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: fields.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(controller: ctrl[f], decoration: InputDecoration(labelText: f, border: const OutlineInputBorder())),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final data = <String, dynamic>{for (final f in fields) f: ctrl[f]!.text.trim()};
              try {
                await FirebaseFirestore.instance
                    .collection('project_data')
                    .doc('${esc(projectId)}')
                    .collection(table.trim())
                    .add(<String, dynamic>{...data, 'createdAt': FieldValue.serverTimestamp()});
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Record saved successfully!')),
                  );
                }
              } catch (e) {
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error saving record: \${e.toString()}')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      ${appBarCode}
      ${bottomNavCode}
      ${fabCode}
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
${widgetCodes.join(',\n') || '            const Center(child: Text(\'Empty screen\'))'}
          ],
        ),
      ),
    );
  }
}`;
    }

    // Build routes map — include /search as a permanent route
    const screenRoutes = screens.map((s, i) => {
        const route = i === 0 ? '/' : `/${dartId(s.id)}`;
        return `        '${route}': (ctx) => const AppScreen${i}()`;
    });
    const allTables = (appConfig.backendConfig || {}).tables || [];
    const tableNamesList = '[' + allTables.map(t => `'${esc(t.name)}'`).join(', ') + ']';
    screenRoutes.push(`        '/search': (ctx) => SearchScreen(projectId: '${esc(projectId)}', tableNames: const ${tableNamesList}, primaryColor: const ${hexColor('#' + rawPrimaryColor)})`);
    const routes = screenRoutes.join(',\n');

    const screenClasses = screens.map((s, i) => genScreen(s, i)).join('\n');

    const primaryColorDart = hexColor('#' + rawPrimaryColor);

    return `import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const GeneratedApp());
}

class GeneratedApp extends StatelessWidget {
  const GeneratedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '${esc(appName)}',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const ${primaryColorDart}),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
${routes}
      },
    );
  }
}
${screenClasses}

// ─── Search Screen ────────────────────────────────────────────────────────────

class SearchScreen extends StatefulWidget {
  final String projectId;
  final List<String> tableNames;
  final Color primaryColor;
  const SearchScreen({super.key, required this.projectId, required this.tableNames, required this.primaryColor});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';
  bool _loading = false;
  final List<Map<String, dynamic>> _allDocs = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    if (widget.tableNames.isEmpty) return;
    setState(() => _loading = true);
    for (final table in widget.tableNames) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('project_data')
            .doc(widget.projectId)
            .collection(table)
            .get();
        for (final doc in snap.docs) {
          final d = Map<String, dynamic>.from(doc.data());
          d['_table'] = table;
          d['_id']    = doc.id;
          _allDocs.add(d);
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return _allDocs.where((doc) {
      final nameVal = (doc['name'] ?? doc.entries
          .where((e) => e.key != '_table' && e.key != '_id' && e.key != 'createdAt')
          .map((e) => e.value)
          .firstOrNull)
          ?.toString().toLowerCase() ?? '';
      return nameVal.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;
    final primary = widget.primaryColor;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search records…',
                prefixIcon: Icon(Icons.search, color: primary),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _query = ''))
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primary, width: 2)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: primary))
                : _query.trim().isEmpty
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.search, size: 56, color: Colors.grey.shade300), const SizedBox(height: 8), Text('Type to search records', style: TextStyle(color: Colors.grey.shade500))]))
                    : results.isEmpty
                        ? Center(child: Text('No results for "\$_query"', style: TextStyle(color: Colors.grey.shade500)))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            itemCount: results.length,
                            itemBuilder: (ctx, i) {
                              final doc = results[i];
                              final tableName = doc['_table'] as String? ?? '';
                              final allKeys = doc.keys.where((k) => k != '_table' && k != '_id' && k != 'createdAt').toList();
                              final nameKey = allKeys.contains('name') ? 'name' : (allKeys.isNotEmpty ? allKeys.first : null);
                              final titleVal = nameKey != null ? (doc[nameKey]?.toString() ?? '') : '';
                              final subKeys = allKeys.where((k) => k != nameKey).take(2).toList();
                              final subParts = subKeys.map((k) => doc[k]?.toString() ?? '').where((v) => v.isNotEmpty).join(' · ');
                              final letter = titleVal.isNotEmpty ? titleVal[0].toUpperCase() : '?';
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: CircleAvatar(backgroundColor: primary, child: Text(letter, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                  title: Text(titleVal, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                                    if (subParts.isNotEmpty) Text(subParts, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                    Text(tableName, style: TextStyle(color: primary, fontSize: 11, fontWeight: FontWeight.w600)),
                                  ]),
                                  isThreeLine: subParts.isNotEmpty,
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

// ─── Stateful helper widgets ──────────────────────────────────────────────────

class _CheckboxWidget extends StatefulWidget {
  const _CheckboxWidget({required this.label, required this.activeColor});
  final String label;
  final Color activeColor;
  @override
  State<_CheckboxWidget> createState() => _CheckboxWidgetState();
}
class _CheckboxWidgetState extends State<_CheckboxWidget> {
  bool _checked = false;
  @override
  Widget build(BuildContext context) => CheckboxListTile(
        value: _checked,
        onChanged: (v) => setState(() => _checked = v ?? false),
        title: Text(widget.label),
        activeColor: widget.activeColor,
      );
}

class _SwitchWidget extends StatefulWidget {
  const _SwitchWidget({required this.label, required this.activeColor});
  final String label;
  final Color activeColor;
  @override
  State<_SwitchWidget> createState() => _SwitchWidgetState();
}
class _SwitchWidgetState extends State<_SwitchWidget> {
  bool _val = false;
  @override
  Widget build(BuildContext context) => SwitchListTile(
        value: _val,
        onChanged: (v) => setState(() => _val = v),
        title: Text(widget.label),
        activeColor: widget.activeColor,
      );
}
`;
}

// ════════════════════════════════════════════════════════════════════════════════
// Gradle & Android File Generators (Kotlin DSL / KTS)
// ════════════════════════════════════════════════════════════════════════════════

function generatePubspec(appConfig) {
    const pkgLeaf = sanitizePackageName(appConfig.name).split('.').pop();
    return `name: ${pkgLeaf}
description: Built with AppForge
publish_to: none
version: 1.0.0+1

environment:
  sdk: ^3.10.3

dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^4.7.0
  cloud_firestore: ^6.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
`;
}

function generateSettingsGradleKts() {
    // Note: \${...} in JS template literal → ${...} in Kotlin (string interpolation)
    return `pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("\${flutterSdkPath}/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
`;
}

function generateProjectBuildGradleKts() {
    // The build directory redirection (../../build) is critical.
    // Without it Gradle puts outputs in android/app/build/ but Flutter's CLI
    // expects them at <projectRoot>/build/app/outputs/flutter-apk/app-release.apk
    return `plugins {
    id("com.google.gms.google-services") version "4.4.4" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
`;
}

function generateAppBuildGradleKts(packageName) {
    return `plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "${packageName}"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "${packageName}"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Sign with debug key for now; replace with your keystore for production
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.10.0"))
    implementation("com.google.firebase:firebase-firestore")
}

flutter {
    source = "../.."
}
`;
}

function generateGradleProperties() {
    return `org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=2G -XX:+HeapDumpOnOutOfMemoryError
org.gradle.parallel=true
org.gradle.caching=true
android.useAndroidX=true
android.enableJetifier=true
`;
}

function generateMainActivityKt(packageName) {
    return `package ${packageName}

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
`;
}

function generateAndroidManifest(appConfig, packageName) {
    const pkg = packageName || sanitizePackageName(appConfig.name);
    return `<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <application
        android:label="${appConfig.name}"
        android:requestLegacyExternalStorage="true">

        <activity
            android:name=".MainActivity"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <meta-data android:name="flutterEmbedding" android:value="2" />
    </application>
</manifest>`;
}

function generateStylesXml() {
    return `<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
`;
}

function generateLaunchBackgroundXml() {
    return `<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@android:color/white" />
</layer-list>
`;
}

function generateColorsXml() {
    return `<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="io_flutter_splash_screen_background">#FFFFFFFF</color>
</resources>
`;
}

function generateGitignore() {
    return `.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
build/
*.class
*.log
.DS_Store
`;
}

function sanitizePackageName(name) {
    const leaf = String(name)
        .toLowerCase()
        .replace(/[^a-z0-9]/g, '_')
        .replace(/_+/g, '_')
        .replace(/^_|_$/g, '')
        .substring(0, 20) || 'app';
    return `com.appforge.${leaf}`;
}

// ════════════════════════════════════════════════════════════════════════════════
// Server Startup & Cleanup
// ════════════════════════════════════════════════════════════════════════════════

function cleanupOldBuilds() {
    const maxAge = 7 * 24 * 60 * 60 * 1000;
    const now = Date.now();
    let count = 0;
    buildStates.forEach((record, buildId) => {
        if (record.endTime && (now - record.endTime) > maxAge) {
            buildStates.delete(buildId);
            try { fs.removeSync(path.join(BUILDS_DIR, buildId)); count++; } catch (e) { }
        }
    });
    if (count > 0) console.log(`🧹 Cleaned up ${count} old build(s)`);
}

setInterval(cleanupOldBuilds, 24 * 60 * 60 * 1000);
cleanupOldBuilds();

app.listen(PORT, '0.0.0.0', () => {
    console.log(`\n${'═'.repeat(60)}`);
    console.log(`🚀 APK Build Server is running!`);
    console.log(`${'═'.repeat(60)}`);
    console.log(`\n📍 Local: http://localhost:${PORT}`);
    console.log(`\n🔗 Endpoints:`);
    console.log(`   GET  /health`);
    console.log(`   POST /api/build/submit`);
    console.log(`   GET  /api/build/status/:id`);
    console.log(`   GET  /api/download/:id`);
    console.log(`\n${'═'.repeat(60)}\n`);
});

module.exports = app;
