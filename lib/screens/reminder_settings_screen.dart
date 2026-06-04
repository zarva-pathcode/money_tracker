import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class ReminderSettingsScreen extends StatelessWidget {
  const ReminderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pengingat Harian',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Aktifkan pengingat agar kamu tidak lupa mencatat transaksi harianmu.",
                    style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSettingsContainer(
            settingsProvider.reminders.map((rem) => _buildReminderTile(context, settingsProvider, rem)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(children: children),
    );
  }

  Widget _buildReminderTile(BuildContext context, SettingsProvider provider, ReminderSetting rem) {
    return _ReminderTileItem(rem: rem, provider: provider);
  }
}

class _ReminderTileItem extends StatelessWidget {
  final ReminderSetting rem;
  final SettingsProvider provider;

  const _ReminderTileItem({required this.rem, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isActive = rem.isActive;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.alarm_rounded, color: Theme.of(context).primaryColor, size: 22),
      ),
      title: Text(rem.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: Text(
        rem.time.format(context),
        style: TextStyle(
          color: isActive ? Theme.of(context).primaryColor : Colors.grey[500],
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: Switch.adaptive(
        value: isActive,
        onChanged: (val) => provider.updateReminder(rem.id, val, rem.time),
        activeColor: Theme.of(context).primaryColor,
      ),
      onTap: isActive ? () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: rem.time,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(primary: Theme.of(context).primaryColor),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          provider.updateReminder(rem.id, true, picked);
        }
      } : null,
    );
  }
}
