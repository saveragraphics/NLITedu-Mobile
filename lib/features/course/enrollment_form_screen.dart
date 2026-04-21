import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/course.dart';
import '../../providers/enrollment_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'payment_webview_screen.dart';


class EnrollmentFormScreen extends ConsumerStatefulWidget {
  final Course course;

  const EnrollmentFormScreen({super.key, required this.course});

  @override
  ConsumerState<EnrollmentFormScreen> createState() => _EnrollmentFormScreenState();
}

class _EnrollmentFormScreenState extends ConsumerState<EnrollmentFormScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  bool _isSubmitting = false;

  // Form Fields
  final _fullNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  String? _gender;
  final _emailController = TextEditingController();
  final _whatsappController = TextEditingController();
  DateTime? _dob;
  
  String? _qualification;
  final _branchController = TextEditingController();
  String? _semester;
  final _collegeNameController = TextEditingController();
  final _brnController = TextEditingController();
  String? _collegeType;
  String? _state;

  final _marks10Controller = TextEditingController();
  final _marks12Controller = TextEditingController();
  final _marksSemController = TextEditingController();
  String? _selectedCourse;

  final List<String> _courseOptions = [
    "AutoCAD 2D & 3D Design",
    "Revit Building Information Modeling (BIM)",
    "Java Programming",
    "Python for Data Science & AI",
    "Python Programming",
    "MATLAB for Scientific Computing",
    "STAAD Pro",
    "SolidWorks",
    "CATIA",
    "Android & iOS Mobile Development",
    "IoT & Embedded Systems"
  ];

  File? _marksheet12;
  File? _marksheetSem;
  final _messageController = TextEditingController();

  late CFPaymentGatewayService _cfPaymentGatewayService;

  final List<String> _states = [
    "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh", 
    "Goa", "Gujarat", "Haryana", "Himachal Pradesh", "Jharkhand", "Karnataka", 
    "Kerala", "Madhya Pradesh", "Maharashtra", "Manipur", "Meghalaya", "Mizoram", 
    "Nagaland", "Odisha", "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu", 
    "Telangana", "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal",
    "Andaman and Nicobar Islands", "Chandigarh", "Dadra and Nagar Haveli and Daman and Diu", 
    "Lakshadweep", "Delhi", "Puducherry", "Ladakh", "Jammu and Kashmir"
  ]..sort();

  @override
  void initState() {
    super.initState();
    _cfPaymentGatewayService = CFPaymentGatewayService();
    _cfPaymentGatewayService.setCallback(_handlePaymentVerify, _handlePaymentError);
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
    }
    _selectedCourse = widget.course.title;
  }

  void _handlePaymentVerify(String orderId) async {
    // Capture data before potential navigation/dispose
    final studentName = _fullNameController.text;
    final studentEmail = _emailController.text;
    
    try {
      await ref.read(enrollmentServiceProvider).confirmPayment(orderId);
      // Invalidate the enrolled status to update UI immediately
      ref.invalidate(isEnrolledProvider(widget.course.title));
      
      if (mounted) {
        context.go('/learning-hub');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enrollment Successful! Welcome to the class.')),
        );
      }

      // 2. Trigger Confirmation Email via Website API
      final enrollmentService = ref.read(enrollmentServiceProvider);
      await enrollmentService.sendEnrollmentEmail(
        studentName: studentName,
        studentEmail: studentEmail,
        courseTitle: widget.course.title,
        orderId: orderId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error confirming enrollment: $e')),
        );
      }
    }
  }

  void _handlePaymentError(CFErrorResponse errorResponse, String orderId) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment Failed: ${errorResponse.getMessage()}')),
      );
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _fatherNameController.dispose();
    _emailController.dispose();
    _whatsappController.dispose();
    _branchController.dispose();
    _collegeNameController.dispose();
    _brnController.dispose();
    _marks10Controller.dispose();
    _marks12Controller.dispose();
    _marksSemController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isSem) async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Consistent with website's 100KB limit
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        if (isSem) {
          _marksheetSem = File(pickedFile.path);
        } else {
          _marksheet12 = File(pickedFile.path);
        }
      });
    }
  }

  double get _currentFee {
    if (_collegeType == null || _state == null) return 0;
    return ref.read(enrollmentServiceProvider).calculateFee(_collegeType!, _state!);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    // TEMPORARY: Make file upload optional for emulator testing
    // if ((_marksheet12 == null && _marksheetSem == null) || (_marksheet12 != null && _marksheetSem != null)) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Please upload ONLY ONE certificate (10th/12th OR Semester marksheet).')),
    //   );
    //   return;
    // }

    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(enrollmentServiceProvider);
      
      // 1. Upload file to Cloudinary (only one will be non-null)
      String? url12;
      String? urlSem;
      
      if (_marksheet12 != null) {
        url12 = await service.uploadToCloudinary(_marksheet12!);
      } else if (_marksheetSem != null) {
        urlSem = await service.uploadToCloudinary(_marksheetSem!);
      }

      // 2. Prepare enrollment data — must match website columns exactly
      final user = Supabase.instance.client.auth.currentUser;
      final enrollmentData = {
        'full_name': _fullNameController.text,
        'father_name': _fatherNameController.text,
        'gender': _gender,
        'email': _emailController.text,
        'whatsapp': _whatsappController.text,
        'dob': _dob?.toIso8601String().split('T')[0],
        'qualification': _qualification,
        'branch': _branchController.text,
        'semester': _semester,
        'college_name': _collegeNameController.text,
        'brn': _brnController.text,
        'college_type': _collegeType,
        'state': _state,
        'course_title': _selectedCourse,
        'message': _messageController.text,
        'marks10': _marks10Controller.text,
        'marks12': _marks12Controller.text,
        'marksSem': _marksSemController.text,
        'marksheet12Url': url12,
        'marksheetSemUrl': urlSem,
        'user_id': user?.id,
      };

      // 3. Initiate Payment
      final orderData = await service.createCashfreeOrder(
        amount: _currentFee,
        email: _emailController.text,
        phone: _whatsappController.text,
      );

      final String paymentSessionId = orderData['payment_session_id'];
      final String orderId = orderData['order_id'];

      // 4. Save Pending to Supabase
      await service.savePendingEnrollment({
        ...enrollmentData,
        'cf_payment_id': orderId,
      });

      // 5. Trigger WebView Payment to bypass "Trusted Source" security check on emulators
      final bool? isSuccess = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => PaymentWebviewScreen(
            paymentSessionId: paymentSessionId,
            orderId: orderId,
          ),
        ),
      );

      if (isSuccess == true) {
        _handlePaymentVerify(orderId);
      } else {
        _handlePaymentError(CFErrorResponse("PAYMENT_CANCELLED", "User cancelled or payment failed", "FAILED", "Error"), orderId);
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Course Enrollment',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: Stepper(
              type: StepperType.horizontal,
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep < 2) {
                  setState(() => _currentStep += 1);
                } else {
                  _submitForm();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep -= 1);
                }
              },
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : details.onStepContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4C00C2),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmitting 
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                              _currentStep == 2 ? 'Pay ₹${_currentFee.toInt()}' : 'Continue',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                        ),
                      ),
                      if (_currentStep > 0) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSubmitting ? null : details.onStepCancel,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Back',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: const Text('Personal'),
                  isActive: _currentStep >= 0,
                  content: Column(
                    children: [
                      _buildTextField(_fullNameController, 'Full Name', LucideIcons.user),
                      _buildTextField(_fatherNameController, 'Father\'s Name', LucideIcons.users),
                      _buildDropdownField(
                        'Gender', 
                        ['Male', 'Female', 'Other'], 
                        (val) => setState(() => _gender = val),
                        value: _gender,
                      ),
                      _buildTextField(_whatsappController, 'WhatsApp Number', LucideIcons.phone, keyboardType: TextInputType.phone),
                      _buildDatePicker(),
                    ],
                  ),
                ),
                Step(
                  title: const Text('Academic'),
                  isActive: _currentStep >= 1,
                  content: Column(
                    children: [
                       _buildDropdownField(
                        'Qualification', 
                        ['Diploma', 'B-Tech', 'BCA', 'MCA', 'BBA/BMS', 'MBA', 'MBBS', 'B.Pharma'], 
                        (val) => setState(() => _qualification = val),
                        value: _qualification,
                      ),
                      _buildTextField(_branchController, 'Branch/Specialization', LucideIcons.briefcase),
                      _buildDropdownField(
                        'Semester', 
                        ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', 'Passed Out'], 
                        (val) => setState(() => _semester = val),
                        value: _semester,
                      ),
                      _buildTextField(_collegeNameController, 'College Name', LucideIcons.school),
                      _buildTextField(_brnController, 'Registration/Roll No.', LucideIcons.hash),
                      _buildDropdownField(
                        'College Type', 
                        ['Government', 'Private'], 
                        (val) => setState(() => _collegeType = val == 'Government' ? 'govt' : 'private'),
                        value: _collegeType == 'govt' ? 'Government' : (_collegeType == 'private' ? 'Private' : null),
                      ),
                       _buildDropdownField(
                        'State', 
                        _states, 
                        (val) => setState(() => _state = val),
                        value: _state,
                      ),
                      if (widget.course.slug == 'general')
                        _buildDropdownField(
                          'Choose Course', 
                          _courseOptions, 
                          (val) => setState(() => _selectedCourse = val),
                          value: _selectedCourse,
                        ),
                      _buildTextField(_messageController, 'Message (Optional)', LucideIcons.messageCircle, required: false),
                    ],
                  ),
                ),
                Step(
                  title: const Text('Marksheets'),
                  isActive: _currentStep >= 2,
                  content: Column(
                    children: [
                      _buildTextField(_marks10Controller, '10th Marks (%)', LucideIcons.award),
                      _buildTextField(_marks12Controller, '12th/Diploma Marks (%)', LucideIcons.award, required: false),
                      _buildTextField(_marksSemController, 'Last Semester Marks (CGPA/%)', LucideIcons.award),
                      const Text(
                        'Note: Please upload ONLY ONE certificate. If you have passed out, upload your latest semester marksheet. Otherwise, upload your 10th/12th marksheet.',
                        style: TextStyle(fontSize: 12, color: Colors.amber, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildFileUpload(
                        '10th/12th Marksheet', 
                        _marksheet12, 
                        () => _pickImage(false),
                        isDisabled: _marksheetSem != null,
                      ),
                      const SizedBox(height: 12),
                      _buildFileUpload(
                        'Last Semester Marksheet', 
                        _marksheetSem, 
                        () => _pickImage(true),
                        isDisabled: _marksheet12 != null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String label, 
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: required 
          ? (value) => value == null || value.isEmpty ? 'Required' : null
          : null,
      ),
    );
  }

  Widget _buildDropdownField(
    String label, 
    List<String> items, 
    ValueChanged<String?> onChanged, {
    String? value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value, // Use value for controlled selection, ignoring deprecated warning for now as initialValue behaves differently in some Flutter versions
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: (value) => value == null ? 'Required' : null,
      ),
    );
  }

  Widget _buildDatePicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
            firstDate: DateTime(1980),
            lastDate: DateTime.now(),
          );
          if (date != null) setState(() => _dob = date);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Date of Birth',
            prefixIcon: const Icon(LucideIcons.calendar, size: 20, color: Colors.grey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Text(_dob == null ? 'Select Date' : _dob!.toString().split(' ')[0]),
        ),
      ),
    );
  }

  Widget _buildFileUpload(String label, File? file, VoidCallback onTap, {bool isDisabled = false}) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isDisabled ? Colors.grey.shade200 : Colors.grey.shade300, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(12),
          color: isDisabled ? Colors.grey.shade100 : Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Icon(
              file == null ? LucideIcons.uploadCloud : LucideIcons.checkCircle, 
              color: isDisabled ? Colors.grey.shade400 : (file == null ? Colors.grey : Colors.green)
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(
              file == null ? label : 'File Uploaded',
              style: TextStyle(color: isDisabled ? Colors.grey : Colors.black87),
            )),
            if (file != null) const Icon(LucideIcons.eye, size: 16, color: Colors.blue),
          ],
        ),
      ),
    );
  }
}
