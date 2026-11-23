import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:provider/provider.dart';
import 'package:trackerapp/data/response/status.dart';
import 'package:trackerapp/providers/device_commands_provider.dart';
import 'package:trackerapp/providers/device_send_command_provider.dart';
import 'package:trackerapp/res/colors.dart';
import 'package:trackerapp/utils/utils.dart';

class ImmobilizerPanel extends StatefulWidget {
  final bool immobilizerValue;
  final String immobilizerStatus;
  final String deviceId;

  const ImmobilizerPanel({
    super.key,
    required this.immobilizerValue,
    required this.immobilizerStatus,
    required this.deviceId,
  });

  @override
  State<ImmobilizerPanel> createState() => _ImmobilizerPanelState();
}

class _ImmobilizerPanelState extends State<ImmobilizerPanel> {
  final ValueNotifier<int> _selectedCommandIndexNotifier =
  ValueNotifier<int>(-1);
  final ValueNotifier<String> _selectedCommandTypeNotifier =
  ValueNotifier<String>('');

  @override
  void dispose() {
    _selectedCommandIndexNotifier.dispose();
    _selectedCommandTypeNotifier.dispose();
    super.dispose();
  }

  Future<void> _showCommandListPicker(BuildContext context) async {
    // Reset selection state
    _selectedCommandIndexNotifier.value = -1;
    _selectedCommandTypeNotifier.value = '';

    if (!mounted) return;

    final commandsProvider = context.read<DeviceCommandsProvider>();
    commandsProvider.resetToLoading();
    commandsProvider.fetchDeviceCommands(widget.deviceId);

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        insetPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.45,
            maxWidth: MediaQuery.of(context).size.width - 62,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    const Icon(Icons.settings_remote_rounded,
                        color: AppColors.buttonColor, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Select Command',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Commands List
              Expanded(
                child: Consumer<DeviceCommandsProvider>(
                  builder: (context, provider, child) {
                    final status = provider.commandsResponse.status;

                    // Show loading spinner while API call is in progress
                    if (status == Status.LOADING) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: AppColors.buttonColor,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Loading commands...',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (status == Status.ERROR) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 50),
                              const SizedBox(height: 12),
                              Text(
                                provider.commandsResponse.errorMessage ??
                                    'Something went wrong',
                                textAlign: TextAlign.center,
                                style:
                                const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: () {
                                  provider.resetToLoading();
                                  provider.fetchDeviceCommands(
                                      widget.deviceId);
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final commands =
                        provider.commandsResponse.data ?? [];
                    final filteredCommands = commands.where((cmd) {
                      final type =
                      (cmd.type?.toString() ?? '').toLowerCase().trim();
                      return type != 'custom' &&
                          type != 'engineresume' &&
                          type != 'enginestop';
                    }).toList();

                    if (filteredCommands.isEmpty) {
                      return const Center(
                        child: Text(
                          'No commands available',
                          style:
                          TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      child: ValueListenableBuilder<int>(
                        valueListenable: _selectedCommandIndexNotifier,
                        builder: (context, selectedIndex, _) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              filteredCommands.length,
                                  (index) {
                                final command = filteredCommands[index];
                                return ListTile(
                                  contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  title: Text(
                                    command.title?.toString() ??
                                        'Unknown Command',
                                    style: AppColors.settingTextstyle,
                                  ),
                                  trailing: Radio<int>(
                                    value: index,
                                    groupValue: selectedIndex,
                                    onChanged: (value) {
                                      if (value != null) {
                                        _selectedCommandIndexNotifier
                                            .value = value;
                                        _selectedCommandTypeNotifier
                                            .value = command.type
                                            ?.toString() ??
                                            '';
                                      }
                                    },
                                    activeColor: AppColors.buttonColor,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

              const Divider(height: 1),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: GFButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        text: 'Cancel',
                        color: Colors.grey.shade400,
                        textStyle: AppColors.settingPageButtonTextStyle,
                        shape: GFButtonShape.pills,
                        size: 42,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ValueListenableBuilder<String>(
                        valueListenable: _selectedCommandTypeNotifier,
                        builder: (context, selectedType, _) {
                          return GFButton(
                            onPressed: selectedType.isEmpty
                                ? null
                                : () {
                              Navigator.pop(dialogContext);
                              _sendCommand(context);
                            },
                            text: 'Send Command',
                            color: AppColors.buttonColor,
                            textStyle: AppColors
                                .settingPageButtonTextStyle
                                .copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            shape: GFButtonShape.pills,
                            size: 42,
                          );
                        },
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

  Future<void> _sendCommand(BuildContext context) async {
    final commandType = _selectedCommandTypeNotifier.value;

    if (commandType.isEmpty) {
      Utils.toastMessage('Please select a command');
      return;
    }

    try {
      final sendCommandProvider =
      context.read<SendDeviceCommandProvider>();
      await sendCommandProvider.sendCommand(commandType, widget.deviceId);
    } catch (e) {
      Utils.toastMessage('Failed to send command: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width - 30,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      margin: const EdgeInsets.fromLTRB(0, 10, 0, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: widget.immobilizerValue
                ? const Icon(Icons.lock, color: Colors.red, size: 32)
                : const Icon(Icons.lock_open_rounded,
                color: Colors.green, size: 32),
          ),
          Expanded(
            flex: 9,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.immobilizerStatus,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: widget.immobilizerValue
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                    GFButton(
                      onPressed: () => _showCommandListPicker(context),
                      text: widget.immobilizerValue ? 'Unlock' : 'Lock',
                      textStyle: AppColors.settingPageButtonTextStyle,
                      color: AppColors.buttonColor,
                      shape: GFButtonShape.pills,
                      size: 25,
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}