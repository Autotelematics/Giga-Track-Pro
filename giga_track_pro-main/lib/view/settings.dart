import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:provider/provider.dart';
import 'package:trackerapp/providers/device_maintenance_provider.dart';
import 'package:trackerapp/providers/expense_record_provider.dart';
import 'package:trackerapp/providers/user_login_provider.dart';
import 'package:trackerapp/repository/change_password_repository.dart';
import 'package:trackerapp/res/colors.dart';
import 'package:trackerapp/services/usersessiondata.dart';
import 'package:trackerapp/utils/logger.dart';
import 'package:trackerapp/utils/permission_helper.dart';
import 'package:trackerapp/utils/routes/routes_name.dart';
import 'package:trackerapp/utils/utils.dart';


class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SettingBody();
  }
}

class _SettingBody extends StatefulWidget {
  const _SettingBody();

  @override
  State<_SettingBody> createState() => _SettingBodyState();
}

class _SettingBodyState extends State<_SettingBody> {

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _fuelPriceController = TextEditingController();

  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseRecordProvider>().fetchExpenseRecords('');
      context.read<DeviceMaintenanceProvider>().fetchMaintenanceList('');
      context.read<UserLoginProvider>().loadUserData();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fuelPriceController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Widget _dialogHeader({
    required IconData icon,
    required String title,
    required Color iconColor,
    required Color iconBgColor,
    VoidCallback? onClose,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        InkWell(
          onTap: onClose ?? () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close,
              size: 20,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    IconData? prefixIcon,
    String? prefixText,
    FocusNode? focusNode,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        validator: validator,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400),

          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, size: 20, color: Colors.grey.shade600)
              : null,

          suffixIcon: suffixIcon,

          prefixText: prefixText,
          prefixStyle: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),

          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _dialogButtons({
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
    required String confirmText,
    required Color confirmColor,
    bool showCancel = true,
  }) {
    return Row(
      children: [
        if (showCancel)
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        if (showCancel) const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              confirmText,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showSuccessDialog({
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 50,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.buttonColor,
      ),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 30, color: Colors.white),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Card(
        shape: AppColors.cardBorderShape,
        child: InkWell(
          onTap: onTap,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: CircleAvatar(
              radius: 16,
              child: Icon(icon, size: 18),
            ),
            title: Text(title, style: AppColors.settingTextstyle),
            trailing: trailing,
          ),
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final userProvider = context.read<UserLoginProvider>();

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    size: 50,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Are you sure you want to logout?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                _dialogButtons(
                  onCancel: () => Navigator.pop(context),
                  onConfirm: () async {
                    Navigator.pop(context);
                    await UserSessionData.performLogout(context);
                  },
                  confirmText: 'Logout',
                  confirmColor: Colors.red.shade700,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    // Clear controllers
    _passwordController.clear();
    _confirmPasswordController.clear();

    final parentContext = context; // Capture the parent context for navigation after pop
    final userProvider = parentContext.read<UserLoginProvider>();
    final repo = ChangePasswordRepository();
    final userApiKey = await userProvider.getUserApiHashString();

    bool isPasswordVisible = false;
    bool isConfirmPasswordVisible = false;
    bool isLoading = false;

    return showDialog(
      context: parentContext,
      barrierDismissible: false, // Prevent accidental closing while loading
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dialogHeader(
                      icon: Icons.lock_rounded,
                      title: 'Change Password',
                      iconColor: Colors.red.shade700,
                      iconBgColor: Colors.red.shade50,
                    ),
                    const SizedBox(height: 20),

                    // Password Field
                    _buildTextField(
                      controller: _passwordController,
                      hintText: 'Enter new password',
                      prefixIcon: Icons.lock_outline,
                      focusNode: _passwordFocusNode,
                      obscureText: !isPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          size: 20,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Confirm Password Field
                    _buildTextField(
                      controller: _confirmPasswordController,
                      hintText: 'Confirm new password',
                      prefixIcon: Icons.lock_outline,
                      focusNode: _confirmPasswordFocusNode,
                      obscureText: !isConfirmPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          size: 20,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            isConfirmPasswordVisible = !isConfirmPasswordVisible;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    if (isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(color: Colors.red),
                        ),
                      )
                    else
                      _dialogButtons(
                        onCancel: () {
                          _passwordController.clear();
                          _confirmPasswordController.clear();
                          Navigator.pop(context);
                        },
                        onConfirm: () async {
                          if (_passwordController.text.isEmpty ||
                              _confirmPasswordController.text.isEmpty) {
                            Utils.flushBarErrorMessage(
                              'Please enter password',
                              context,
                            );
                            return;
                          }

                          if (_passwordController.text != _confirmPasswordController.text) {
                            _passwordController.clear();
                            _confirmPasswordController.clear();
                            _passwordFocusNode.requestFocus();

                            Utils.flushBarErrorMessage(
                              'Passwords do not match',
                              context,
                            );
                            return;
                          }

                          final password = _passwordController.text;

                          // Show loading inside dialog
                          setDialogState(() {
                            isLoading = true;
                          });

                          try {
                            AppLogger.info('🔑 Attempting to change password...');
                            final response = await repo.changePasswordFromApi(
                              userApiKey,
                              password,
                            );

                            final String message = response["message"] ?? "Something went wrong";
                            final String status = (response["status"] ?? "").toString();

                            AppLogger.info('DEBUG: Change Password Response: $response');

                            if (status == '1') {
                              AppLogger.success('✅ Password changed successfully on server');

                              // Close the dialog using dialogContext
                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop();
                              }

                              // Use parentContext for messages and navigation
                              if (parentContext.mounted) {
                                Utils.flushBarSuccessMessage('Password changed successfully. Logging out...', parentContext);

                                // Wait for user to see the success message
                                await Future.delayed(const Duration(seconds: 2));

                                AppLogger.info('🚀 Initiating logout...');
                                if (parentContext.mounted) {
                                  await UserSessionData.performLogout(parentContext);
                                }
                              }
                            } else {
                              // API returned error status
                              setDialogState(() {
                                isLoading = false;
                              });
                              if (context.mounted) {
                                Utils.flushBarErrorMessage(message, context);
                              }
                            }
                          } catch (e) {
                            // Network or other error
                            setDialogState(() {
                              isLoading = false;
                            });
                            AppLogger.error('❌ Error changing password', e);
                            if (context.mounted) {
                              Utils.flushBarErrorMessage('Failed to change password. Please try again.', context);
                            }
                          }
                        },
                        confirmText: 'Change',
                        confirmColor: Colors.red.shade700,
                      ),
              ],
            ),
          ),
        );
          },
        );
      },
    );
  }

  Future<void> _showFuelDialog(UserLoginProvider userProvider) async {
    _fuelPriceController.text = userProvider.fuelPrice.toString();

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogHeader(
                icon: Icons.gas_meter_rounded,
                title: 'Set Fuel Price',
                iconColor: Colors.orange.shade700,
                iconBgColor: Colors.orange.shade50,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _fuelPriceController,
                hintText: 'Enter fuel price per liter',
                prefixIcon: null,
                prefixText: 'PKR ',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter price';
                  }
                  final val = double.tryParse(value);
                  if (val == null || val < 200 || val > 1000) {
                    return 'Price must be between 200-1000';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              Text(
                'Price range: PKR 200 - 1000',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              _dialogButtons(
                onCancel: () {
                  _fuelPriceController.clear();
                  Navigator.pop(ctx);
                },
                onConfirm: () {
                  final val = double.tryParse(_fuelPriceController.text);
                  if (val == null || val < 200 || val > 1000) {
                    Utils.toastMessage(
                      'Please enter value from 200 to 1000 range',
                    );
                    return;
                  }
                  userProvider.updateFuelPrice(val);
                  Navigator.pop(ctx);
                },
                confirmText: 'Set Price',
                confirmColor: Colors.orange.shade700,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserLoginProvider>();
    final expenseProvider = context.watch<ExpenseRecordProvider>();
    final maintenanceProvider = context.watch<DeviceMaintenanceProvider>();


    // ✅ Check if user can view devices


    // ✅ Check if user can view geofences

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Settings', style: AppColors.appTitleTextStyle),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _section('Profile', Icons.person),
              const SizedBox(height: 5),

              // Profile Card with Logout
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Card(
                  shape: AppColors.cardBorderShape,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    leading: const CircleAvatar(
                      radius: 16,
                      child: Icon(Icons.person),
                    ),
                    title: Text(
                      userProvider.userId ?? 'User ID',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    trailing: GFButton(
                      onPressed: () => _showLogoutDialog(context),
                      text: 'Logout',
                      color: Colors.red.shade700,
                      shape: GFButtonShape.pills,
                      size: GFSize.SMALL,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),

              // ✅ Password Card with Change Password - Always Show
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Card(
                    shape: AppColors.cardBorderShape,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: const CircleAvatar(
                        radius: 16,
                        child: Icon(Icons.key),
                      ),
                      title: const Text(
                        'Password',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      trailing: GFButton(
                        onPressed: () => _showChangePasswordDialog(context),
                        text: 'Change',
                        color: Colors.red.shade700,
                        shape: GFButtonShape.pills,
                        size: GFSize.SMALL,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 5),

              _section('Tools', Icons.settings),

              // ✅ Geofence Settings - Only show if user has permission
                _tile(
                  icon: Icons.fence,
                  title: 'Geofence Settings',
                  onTap: () =>
                      Navigator.pushNamed(context, RoutesName.geoFenceList),
                  trailing: const Icon(Icons.arrow_forward),
                ),

              // ✅ Alerts Settings - Always Show
                _tile(
                  icon: Icons.notifications,
                  title: 'Alerts Settings',
                  onTap: () =>
                      Navigator.pushNamed(context, RoutesName.alertsTypeList),
                  trailing: const Icon(Icons.arrow_forward),
                ),

              // Play Alerts Announcement - Always visible
              _tile(
                icon: Icons.speaker,
                title: 'Play Alerts Announcement',
                trailing: Checkbox(
                  value: userProvider.alertSounds,
                  onChanged: (val) =>
                      userProvider.updateAlertSounds(val ?? true),
                ),
              ),

              // Fuel Cost - Always visible
              _tile(
                icon: Icons.gas_meter_outlined,
                title: 'Fuel Cost: Rs.${userProvider.fuelPrice}/ltr',
                trailing: GFButton(
                  onPressed: () => _showFuelDialog(userProvider),
                  text: 'Set Price',
                  color: Colors.orange.shade700,
                  shape: GFButtonShape.pills,
                  size: GFSize.SMALL,
                ),
              ),

              // ✅ Vehicle Expenses - Only show if user has permission
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Card(
                    shape: AppColors.cardBorderShape,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: const CircleAvatar(
                        maxRadius: 16,
                        backgroundColor: Colors.blueAccent,
                        child: Icon(Icons.attach_money_outlined, size: 18),
                      ),
                      title: Text(
                        'Vehicle Expenses',
                        style: AppColors.settingTextstyle,
                      ),
                      trailing: Text('Rs.${expenseProvider.totalAmount}'),
                      onTap: () => Navigator.pushNamed(
                        context,
                        RoutesName.viewExpenseScreen,
                        arguments: {'vehicleId': ''},
                      ),
                    ),
                  ),
                ),

              // ✅ Maintenance - Only show if user has permission
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Card(
                    shape: AppColors.cardBorderShape,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: CircleAvatar(
                        maxRadius: 16,
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.car_repair, size: 18),
                      ),
                      title: Text(
                        'Maintenance',
                        style: AppColors.settingTextstyle,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            maxRadius: 16,
                            child: Text(
                              maintenanceProvider.maintenanceList.length
                                  .toString(),
                            ),
                          ),
                          const SizedBox(width: 3),
                          InkWell(
                            onTap: () => Navigator.pushNamed(
                              context,
                              RoutesName.addVehicleMaintenanceScreen,
                            ),
                            child: const CircleAvatar(
                              maxRadius: 16,
                              child: Text('+'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}