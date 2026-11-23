import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackerapp/data/globalsharedveriables.dart';
import 'package:trackerapp/providers/all_devices_on_map_provider.dart';
import 'package:trackerapp/providers/auth_provider.dart';
import 'package:trackerapp/providers/device_live_tracking_provider.dart';
import 'package:trackerapp/providers/get_alert_provider.dart';
import 'package:trackerapp/providers/get_devices_list_provider.dart';
import 'package:trackerapp/providers/user_login_provider.dart';
import 'package:trackerapp/res/colors.dart';
import 'package:trackerapp/utils/routes/routes_name.dart';
import 'package:trackerapp/utils/utils.dart';
import 'package:trackerapp/services/usersessiondata.dart';
import 'package:trackerapp/utils/logger.dart';
import 'package:url_launcher/url_launcher.dart';
import '../res/components/submitbutton.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  FocusNode emailFocusNode = FocusNode();
  FocusNode passwordFocusNode = FocusNode();

  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _launchURLBrowser(String link) async {
    var url = Uri.parse(link);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  bool _validate(BuildContext context) {
    if (emailController.text.isEmpty) {
      Utils.flushBarErrorMessage('Please enter email', context);
      return false;
    }

    if (passwordController.text.isEmpty) {
      Utils.flushBarErrorMessage('Please enter password', context);
      return false;
    }

    return true;
  }

  void _resetDataProviders(BuildContext context) {
    try {
      context.read<GetDevicesListProvider>().reset();
      context.read<AlertsProvider>().reset();
      context.read<AllDevicesOnMapProvider>().reset();
      context.read<VehicleTrackingProvider>().reset();
      vehicleNames.clear();
      vehiclesNamesIdMap.clear();
    } catch (e) {
      AppLogger.warning('Error resetting providers on login: $e');
    }
  }

  Future<void> _handleLogin(
      BuildContext context,
      AuthProvider authProvider,
      UserLoginProvider userLoginProvider,
      ) async {
    if (!_validate(context)) return;

    setState(() {
      _isLoading = true;
    });

    // ✅ Reset all data providers and globals before logging in to ensure no old session data persists
    _resetDataProviders(context);

    Map<String, dynamic> loginData = {
      'email': emailController.text.trim(),
      'password': passwordController.text.trim(),
    };

    try {
      final loginSuccess = await authProvider.loginApi(loginData, context);

      if (loginSuccess && context.mounted) {
        if (authProvider.userData != null) {
          final apiHash = authProvider.userData!.userApiHash ?? '';

          // ✅ Save session with permissions from authProvider
          AppLogger.info('📝 Saving permissions: ${authProvider.permissions}');

          await userLoginProvider.saveUserSession(
            authProvider.userData!,
            emailController.text.trim(),
            permissions: authProvider.permissions,
          );

          // ✅ Verify permissions were saved
          AppLogger.success('✅ Permissions saved successfully');
          AppLogger.info('📋 Permissions in memory: ${userLoginProvider.permissions}');

          // ✅ Get first accessible category to navigate to
          String? firstCategory = authProvider.getFirstAccessibleCategory();
          AppLogger.info('📋 First accessible category: $firstCategory');

          Utils.toastMessage('Login successful');

          // ✅ Navigate to home with the first accessible category
          Navigator.pushNamedAndRemoveUntil(
            context,
            RoutesName.home,
                (route) => false,
          );

          // Submit FCM token in background
          _submitFcmTokenInBackground(apiHash);
        }
      }
    } catch (e) {
      Utils.flushBarErrorMessage('Login failed: ${e.toString()}', context);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _submitFcmTokenInBackground(String apiHash) {
    Future.delayed(const Duration(milliseconds: 500), () {
      final userSession = UserSessionData();
      userSession.submitFcmToken(apiHash);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              /// Company Logo
              SizedBox(
                width: 250,
                height: 100,
                child: Transform.scale(
                  scale: 4.3,
                  child: Image.asset(
                    "assets/images/company_logo.png",
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              const Padding(
                padding: EdgeInsets.fromLTRB(30, 10, 0, 0),
                child: Row(
                  children: [
                    Text(
                      "Sign in!",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xff000000),
                      ),
                    ),
                  ],
                ),
              ),

              /// EMAIL
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                child: TextField(
                  controller: emailController,
                  focusNode: emailFocusNode,
                  cursorColor: AppColors.buttonColor,
                  keyboardType: TextInputType.emailAddress,
                  onSubmitted: (value) {
                    Utils.fieldFocusChange(
                        context, emailFocusNode, passwordFocusNode);
                  },
                  decoration: InputDecoration(
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.buttonColor,
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    labelText: "Email",
                    labelStyle: const TextStyle(color: Colors.black),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    prefixIcon: const Icon(Icons.person, size: 18),
                  ),
                ),
              ),

              /// PASSWORD
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                child: TextField(
                  controller: passwordController,
                  focusNode: passwordFocusNode,
                  obscureText: authProvider.isPasswordHidden,
                  cursorColor: AppColors.buttonColor,
                  decoration: InputDecoration(
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.buttonColor,
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    labelText: "Password",
                    labelStyle: const TextStyle(color: Colors.black),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    prefixIcon: const Icon(Icons.vpn_key, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        authProvider.isPasswordHidden
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        authProvider.togglePasswordVisibility();
                      },
                    ),
                  ),
                ),
              ),

              /// BUTTON
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
                child: SubmitButton(
                  loading: authProvider.isLoading || _isLoading,
                  onPress: () => _handleLogin(
                    context,
                    authProvider,
                    context.read<UserLoginProvider>(),
                  ),
                  title: 'Sign In',
                ),
              ),

              /// FOOTER
              Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Don\'t have an account? ',
                      style: TextStyle(fontSize: 16),
                    ),

                    /// Contact Us Gmail Account
                    GestureDetector(
                      onTap: () =>
                          _launchURLBrowser('mailto:gigatrack786@gmail.com'),
                      child: const Text(
                        'Contact Us',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: AppColors.buttonColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}