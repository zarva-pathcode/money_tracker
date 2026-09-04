import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class ReminderSettingsScreen extends StatelessWidget {
  const ReminderSettingsScreen({super.key});

  void _showReminderSheet(BuildContext context, SettingsProvider provider, {ReminderSetting? existingRem}) {
    final labelController = TextEditingController(text: existingRem?.label ?? '');
    TimeOfDay selectedTime = existingRem?.time ?? TimeOfDay.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    existingRem == null ? 'Tambah Pengingat Baru' : 'Edit Pengingat',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: labelController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Nama Pengingat',
                      hintText: 'Misal: Olahraga, Bayar Tagihan, dll.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.label_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    leading: Icon(Icons.access_time_rounded, color: Theme.of(context).primaryColor),
                    title: const Text('Waktu Pengingat', style: TextStyle(fontSize: 14)),
                    trailing: Text(
                      selectedTime.format(context),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setState(() {
                          selectedTime = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final text = labelController.text.trim();
                        if (text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Label pengingat tidak boleh kosong')),
                          );
                          return;
                        }
                        Navigator.pop(ctx);
                        if (existingRem == null) {
                          provider.addReminder(text, selectedTime);
                        } else {
                          provider.updateReminder(existingRem.id, existingRem.isActive, selectedTime, newLabel: text);
                        }
                      },
                      child: const Text(
                        'Simpan Pengingat',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, SettingsProvider provider, ReminderSetting rem) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Pengingat?'),
        content: Text('Apakah kamu yakin ingin menghapus pengingat "${rem.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteReminder(rem.id);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

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
          if (settingsProvider.reminders.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  "Belum ada pengingat. Klik '+ Tambah Pengingat' untuk membuat.",
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            _buildSettingsContainer(
              settingsProvider.reminders
                  .map((rem) => _buildReminderTile(context, settingsProvider, rem))
                  .toList(),
            ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: Theme.of(context).primaryColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => _showReminderSheet(context, settingsProvider),
            icon: Icon(Icons.add_rounded, color: Theme.of(context).primaryColor),
            label: Text(
              'Tambah Pengingat',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
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
    return _ReminderTileItem(
      rem: rem,
      provider: provider,
      onDelete: () => _confirmDelete(context, provider, rem),
      onEdit: () => _showReminderSheet(context, provider, existingRem: rem),
    );
  }
}

class _ReminderTileItem extends StatelessWidget {
  final ReminderSetting rem;
  final SettingsProvider provider;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ReminderTileItem({
    required this.rem,
    required this.provider,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = rem.isActive;
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 20, right: 8, top: 4, bottom: 4),
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch.adaptive(
            value: isActive,
            onChanged: (val) => provider.updateReminder(rem.id, val, rem.time),
            activeColor: Theme.of(context).primaryColor,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
            onPressed: onDelete,
            tooltip: 'Hapus Pengingat',
          ),
        ],
      ),
      onTap: onEdit,
    );
  }
}
