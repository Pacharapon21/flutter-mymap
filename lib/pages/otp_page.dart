import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import 'login_page.dart';

class OtpPage extends StatefulWidget {
  final String email;

  const OtpPage({Key? key, required this.email}) : super(key: key);

  @override
  _OtpPageState createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  void _verifyOtp() async {
    if (_otpController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter OTP',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.verifyOtp(widget.email, _otpController.text);
      Get.snackbar('Success', 'Email verified successfully! Please login.',
          backgroundColor: Colors.green, colorText: Colors.white);
      Get.offAll(() => LoginPage());
    } catch (e) {
      Get.snackbar('Verification Failed', e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resendOtp() async {
    try {
      await _apiService.resendOtp(widget.email);
      Get.snackbar('Success', 'New OTP has been sent to your email',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to resend OTP',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_read, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            Text(
              'Enter the 6-digit OTP sent to\n${widget.email}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(
                labelText: 'OTP',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.security),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Verify'),
                    ),
                  ),
            TextButton(
              onPressed: _resendOtp,
              child: const Text('Resend OTP'),
            )
          ],
        ),
      ),
    );
  }
}
