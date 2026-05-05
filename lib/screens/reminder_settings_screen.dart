import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class ReminderSettingsScreen extends StatelessWidget {
  const ReminderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
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
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Aktifkan pengingat agar kamu tidak lupa mencatat transaksi harianmu.",
                    style: TextStyle(color: Colors.blue[900], fontSize: 13, height: 1.4),
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

class _ReminderTileItem extends StatefulWidget {
  final ReminderSetting rem;
  final SettingsProvider provider;

  const _ReminderTileItem({required this.rem, required this.provider});

  @override
  State<_ReminderTileItem> createState() => _ReminderTileItemState();
}

class _ReminderTileItemState extends State<_ReminderTileItem> {
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _isActive = widget.rem.isActive;
  }

  @override
  void didUpdateWidget(_ReminderTileItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rem.isActive != widget.rem.isActive) {
      _isActive = widget.rem.isActive;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.alarm_rounded, color: Colors.blue, size: 22),
      ),
      title: Text(widget.rem.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: Text(
        widget.rem.time.format(context),
        style: TextStyle(
          color: _isActive ? Colors.blue : Colors.grey[500],
          fontWeight: _isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: Switch.adaptive(
        value: _isActive,
        onChanged: (val) {
          setState(() => _isActive = val);
          widget.provider.updateReminder(widget.rem.id, val, widget.rem.time);
        },
        activeColor: Colors.blue,
      ),
      onTap: _isActive ? () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: widget.rem.time,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(primary: Colors.blue),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          widget.provider.updateReminder(widget.rem.id, true, picked);
        }
      } : null,
    );
  }
}
