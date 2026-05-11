class BackendTemplate {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final String category;
  final List<BackendField> availableFields;
  final List<String> defaultFields;

  const BackendTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.category,
    required this.availableFields,
    required this.defaultFields,
  });
}

class BackendField {
  final String name;
  final String type;
  final String description;
  final bool required;
  final dynamic defaultValue;

  const BackendField({
    required this.name,
    required this.type,
    required this.description,
    this.required = false,
    this.defaultValue,
  });
}

// ── All built-in backend templates ───────────────────────────────────────────
class BackendTemplates {
  BackendTemplates._();

  static const List<String> categories = [
    'All',
    'Education',
    'Business',
    'E-commerce',
    'Healthcare',
    'Management',
    'Custom',
  ];

  static final List<BackendTemplate> all = [
    // ── Education Templates ──────────────────────────────────────────────────
    BackendTemplate(
      id: 'student',
      name: 'Student',
      description:
          'Manage student information, enrollment, and academic records.',
      emoji: '🎓',
      category: 'Education',
      defaultFields: ['name', 'email', 'phone', 'enrollment_date'],
      availableFields: [
        BackendField(
          name: 'name',
          type: 'String',
          description: 'Full name of the student',
          required: true,
        ),
        BackendField(
          name: 'email',
          type: 'String',
          description: 'Student email address',
          required: true,
        ),
        BackendField(
          name: 'phone',
          type: 'String',
          description: 'Contact phone number',
        ),
        BackendField(
          name: 'roll_number',
          type: 'String',
          description: 'Unique roll number',
        ),
        BackendField(
          name: 'class',
          type: 'String',
          description: 'Current class/grade',
        ),
        BackendField(
          name: 'section',
          type: 'String',
          description: 'Class section (A, B, C, etc.)',
        ),
        BackendField(
          name: 'date_of_birth',
          type: 'DateTime',
          description: 'Student date of birth',
        ),
        BackendField(
          name: 'address',
          type: 'String',
          description: 'Home address',
        ),
        BackendField(
          name: 'parent_name',
          type: 'String',
          description: 'Parent/guardian name',
        ),
        BackendField(
          name: 'parent_phone',
          type: 'String',
          description: 'Parent contact number',
        ),
        BackendField(
          name: 'enrollment_date',
          type: 'DateTime',
          description: 'Date of enrollment',
        ),
        BackendField(
          name: 'status',
          type: 'String',
          description: 'Active/Inactive status',
          defaultValue: 'active',
        ),
      ],
    ),

    BackendTemplate(
      id: 'teacher',
      name: 'Teacher',
      description: 'Manage teacher profiles, subjects, and assignments.',
      emoji: '👨‍🏫',
      category: 'Education',
      defaultFields: ['name', 'email', 'subject', 'qualification'],
      availableFields: [
        BackendField(
          name: 'name',
          type: 'String',
          description: 'Full name of the teacher',
          required: true,
        ),
        BackendField(
          name: 'email',
          type: 'String',
          description: 'Teacher email address',
          required: true,
        ),
        BackendField(
          name: 'phone',
          type: 'String',
          description: 'Contact phone number',
        ),
        BackendField(
          name: 'employee_id',
          type: 'String',
          description: 'Unique employee ID',
        ),
        BackendField(
          name: 'subject',
          type: 'String',
          description: 'Primary subject taught',
          required: true,
        ),
        BackendField(
          name: 'qualification',
          type: 'String',
          description: 'Educational qualification',
          required: true,
        ),
        BackendField(
          name: 'experience_years',
          type: 'int',
          description: 'Years of teaching experience',
        ),
        BackendField(
          name: 'date_of_joining',
          type: 'DateTime',
          description: 'Date of joining the institution',
        ),
        BackendField(
          name: 'salary',
          type: 'double',
          description: 'Monthly salary',
        ),
        BackendField(
          name: 'address',
          type: 'String',
          description: 'Home address',
        ),
        BackendField(
          name: 'status',
          type: 'String',
          description: 'Active/Inactive status',
          defaultValue: 'active',
        ),
      ],
    ),

    // ── Business Templates ───────────────────────────────────────────────────
    BackendTemplate(
      id: 'user',
      name: 'User',
      description: 'Basic user management with authentication and profiles.',
      emoji: '👤',
      category: 'Business',
      defaultFields: ['name', 'email', 'phone', 'role'],
      availableFields: [
        BackendField(
          name: 'name',
          type: 'String',
          description: 'Full name',
          required: true,
        ),
        BackendField(
          name: 'email',
          type: 'String',
          description: 'Email address',
          required: true,
        ),
        BackendField(
          name: 'phone',
          type: 'String',
          description: 'Phone number',
        ),
        BackendField(
          name: 'role',
          type: 'String',
          description: 'User role (admin, user, etc.)',
          defaultValue: 'user',
        ),
        BackendField(
          name: 'department',
          type: 'String',
          description: 'Department or team',
        ),
        BackendField(
          name: 'date_of_birth',
          type: 'DateTime',
          description: 'Date of birth',
        ),
        BackendField(name: 'address', type: 'String', description: 'Address'),
        BackendField(
          name: 'profile_image',
          type: 'String',
          description: 'Profile image URL',
        ),
        BackendField(
          name: 'is_active',
          type: 'bool',
          description: 'Account active status',
          defaultValue: true,
        ),
        BackendField(
          name: 'created_at',
          type: 'DateTime',
          description: 'Account creation date',
        ),
      ],
    ),

    BackendTemplate(
      id: 'admin',
      name: 'Admin',
      description: 'Administrative user management with elevated permissions.',
      emoji: '👑',
      category: 'Business',
      defaultFields: ['name', 'email', 'permissions', 'department'],
      availableFields: [
        BackendField(
          name: 'name',
          type: 'String',
          description: 'Full name',
          required: true,
        ),
        BackendField(
          name: 'email',
          type: 'String',
          description: 'Email address',
          required: true,
        ),
        BackendField(
          name: 'phone',
          type: 'String',
          description: 'Phone number',
        ),
        BackendField(
          name: 'permissions',
          type: 'List<String>',
          description: 'List of permissions',
          required: true,
        ),
        BackendField(
          name: 'department',
          type: 'String',
          description: 'Department',
          required: true,
        ),
        BackendField(
          name: 'level',
          type: 'String',
          description: 'Admin level (super, senior, junior)',
          defaultValue: 'junior',
        ),
        BackendField(
          name: 'last_login',
          type: 'DateTime',
          description: 'Last login timestamp',
        ),
        BackendField(
          name: 'is_super_admin',
          type: 'bool',
          description: 'Super admin privileges',
          defaultValue: false,
        ),
      ],
    ),

    // ── E-commerce Templates ─────────────────────────────────────────────────
    BackendTemplate(
      id: 'customer',
      name: 'Customer',
      description: 'Customer management for e-commerce and service businesses.',
      emoji: '🛍️',
      category: 'E-commerce',
      defaultFields: ['name', 'email', 'phone', 'address'],
      availableFields: [
        BackendField(
          name: 'name',
          type: 'String',
          description: 'Customer full name',
          required: true,
        ),
        BackendField(
          name: 'email',
          type: 'String',
          description: 'Email address',
          required: true,
        ),
        BackendField(
          name: 'phone',
          type: 'String',
          description: 'Phone number',
        ),
        BackendField(
          name: 'address',
          type: 'String',
          description: 'Shipping/billing address',
          required: true,
        ),
        BackendField(
          name: 'date_of_birth',
          type: 'DateTime',
          description: 'Date of birth',
        ),
        BackendField(
          name: 'loyalty_points',
          type: 'int',
          description: 'Loyalty points balance',
          defaultValue: 0,
        ),
        BackendField(
          name: 'total_orders',
          type: 'int',
          description: 'Total number of orders',
          defaultValue: 0,
        ),
        BackendField(
          name: 'total_spent',
          type: 'double',
          description: 'Total amount spent',
          defaultValue: 0.0,
        ),
        BackendField(
          name: 'preferred_payment',
          type: 'String',
          description: 'Preferred payment method',
        ),
        BackendField(
          name: 'newsletter_subscribed',
          type: 'bool',
          description: 'Newsletter subscription status',
          defaultValue: false,
        ),
        BackendField(
          name: 'created_at',
          type: 'DateTime',
          description: 'Account creation date',
        ),
      ],
    ),

    BackendTemplate(
      id: 'order',
      name: 'Order',
      description: 'Order management for e-commerce transactions.',
      emoji: '📦',
      category: 'E-commerce',
      defaultFields: ['customer_id', 'items', 'total_amount', 'status'],
      availableFields: [
        BackendField(
          name: 'order_number',
          type: 'String',
          description: 'Unique order number',
          required: true,
        ),
        BackendField(
          name: 'customer_id',
          type: 'String',
          description: 'Customer ID',
          required: true,
        ),
        BackendField(
          name: 'items',
          type: 'List<Map<String, dynamic>>',
          description: 'List of ordered items',
          required: true,
        ),
        BackendField(
          name: 'total_amount',
          type: 'double',
          description: 'Total order amount',
          required: true,
        ),
        BackendField(
          name: 'status',
          type: 'String',
          description: 'Order status',
          defaultValue: 'pending',
        ),
        BackendField(
          name: 'payment_status',
          type: 'String',
          description: 'Payment status',
          defaultValue: 'pending',
        ),
        BackendField(
          name: 'shipping_address',
          type: 'String',
          description: 'Shipping address',
        ),
        BackendField(
          name: 'billing_address',
          type: 'String',
          description: 'Billing address',
        ),
        BackendField(
          name: 'payment_method',
          type: 'String',
          description: 'Payment method used',
        ),
        BackendField(
          name: 'order_date',
          type: 'DateTime',
          description: 'Order placement date',
          required: true,
        ),
        BackendField(
          name: 'delivery_date',
          type: 'DateTime',
          description: 'Expected delivery date',
        ),
        BackendField(
          name: 'tracking_number',
          type: 'String',
          description: 'Shipping tracking number',
        ),
      ],
    ),

    // ── Healthcare Templates ─────────────────────────────────────────────────
    BackendTemplate(
      id: 'patient',
      name: 'Patient',
      description: 'Patient management for healthcare facilities.',
      emoji: '🏥',
      category: 'Healthcare',
      defaultFields: ['name', 'email', 'phone', 'date_of_birth'],
      availableFields: [
        BackendField(
          name: 'name',
          type: 'String',
          description: 'Patient full name',
          required: true,
        ),
        BackendField(
          name: 'email',
          type: 'String',
          description: 'Email address',
        ),
        BackendField(
          name: 'phone',
          type: 'String',
          description: 'Phone number',
          required: true,
        ),
        BackendField(
          name: 'patient_id',
          type: 'String',
          description: 'Unique patient ID',
          required: true,
        ),
        BackendField(
          name: 'date_of_birth',
          type: 'DateTime',
          description: 'Date of birth',
          required: true,
        ),
        BackendField(name: 'gender', type: 'String', description: 'Gender'),
        BackendField(
          name: 'blood_type',
          type: 'String',
          description: 'Blood type',
        ),
        BackendField(
          name: 'emergency_contact',
          type: 'String',
          description: 'Emergency contact name',
        ),
        BackendField(
          name: 'emergency_phone',
          type: 'String',
          description: 'Emergency contact phone',
        ),
        BackendField(
          name: 'medical_history',
          type: 'List<String>',
          description: 'Medical history conditions',
        ),
        BackendField(
          name: 'allergies',
          type: 'List<String>',
          description: 'Known allergies',
        ),
        BackendField(
          name: 'insurance_provider',
          type: 'String',
          description: 'Insurance provider',
        ),
        BackendField(
          name: 'insurance_number',
          type: 'String',
          description: 'Insurance policy number',
        ),
        BackendField(
          name: 'last_visit',
          type: 'DateTime',
          description: 'Last visit date',
        ),
      ],
    ),

    // ── Management Templates ─────────────────────────────────────────────────
    BackendTemplate(
      id: 'employee',
      name: 'Employee',
      description: 'Employee management for HR and organizational purposes.',
      emoji: '👔',
      category: 'Management',
      defaultFields: ['name', 'email', 'department', 'position'],
      availableFields: [
        BackendField(
          name: 'name',
          type: 'String',
          description: 'Employee full name',
          required: true,
        ),
        BackendField(
          name: 'email',
          type: 'String',
          description: 'Work email address',
          required: true,
        ),
        BackendField(
          name: 'phone',
          type: 'String',
          description: 'Phone number',
        ),
        BackendField(
          name: 'employee_id',
          type: 'String',
          description: 'Unique employee ID',
          required: true,
        ),
        BackendField(
          name: 'department',
          type: 'String',
          description: 'Department',
          required: true,
        ),
        BackendField(
          name: 'position',
          type: 'String',
          description: 'Job position/title',
          required: true,
        ),
        BackendField(
          name: 'manager_id',
          type: 'String',
          description: 'Manager employee ID',
        ),
        BackendField(
          name: 'salary',
          type: 'double',
          description: 'Annual salary',
        ),
        BackendField(
          name: 'hire_date',
          type: 'DateTime',
          description: 'Date of hire',
        ),
        BackendField(
          name: 'status',
          type: 'String',
          description: 'Employment status',
          defaultValue: 'active',
        ),
        BackendField(
          name: 'work_location',
          type: 'String',
          description: 'Work location/office',
        ),
        BackendField(
          name: 'skills',
          type: 'List<String>',
          description: 'Employee skills',
        ),
      ],
    ),

    BackendTemplate(
      id: 'project',
      name: 'Project',
      description: 'Project management and tracking.',
      emoji: '📋',
      category: 'Management',
      defaultFields: ['name', 'description', 'status', 'start_date'],
      availableFields: [
        BackendField(
          name: 'name',
          type: 'String',
          description: 'Project name',
          required: true,
        ),
        BackendField(
          name: 'description',
          type: 'String',
          description: 'Project description',
        ),
        BackendField(
          name: 'status',
          type: 'String',
          description: 'Project status',
          defaultValue: 'planning',
        ),
        BackendField(
          name: 'priority',
          type: 'String',
          description: 'Project priority',
          defaultValue: 'medium',
        ),
        BackendField(
          name: 'start_date',
          type: 'DateTime',
          description: 'Project start date',
          required: true,
        ),
        BackendField(
          name: 'end_date',
          type: 'DateTime',
          description: 'Project end date',
        ),
        BackendField(
          name: 'budget',
          type: 'double',
          description: 'Project budget',
        ),
        BackendField(
          name: 'manager_id',
          type: 'String',
          description: 'Project manager ID',
        ),
        BackendField(
          name: 'team_members',
          type: 'List<String>',
          description: 'Team member IDs',
        ),
        BackendField(
          name: 'progress_percentage',
          type: 'int',
          description: 'Completion percentage',
          defaultValue: 0,
        ),
        BackendField(
          name: 'created_at',
          type: 'DateTime',
          description: 'Project creation date',
        ),
      ],
    ),
  ];

  static List<BackendTemplate> getByCategory(String category) {
    if (category == 'All') return all;
    return all.where((template) => template.category == category).toList();
  }

  static BackendTemplate? getById(String id) {
    return all.firstWhere((template) => template.id == id);
  }
}
