import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_logger.dart';

class LogViewerDialog extends StatefulWidget {
  const LogViewerDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => const LogViewerDialog(),
    );
  }

  @override
  State<LogViewerDialog> createState() => _LogViewerDialogState();
}

class _LogViewerDialogState extends State<LogViewerDialog> {
  @override
  Widget build(BuildContext context) {
    final logs = AppLogger.logs;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.terminal_rounded, color: Color(0xFF002E69)),
                  const SizedBox(width: 8),
                  Text(
                    'Log Aplikasi Udayana',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Bersihkan Log',
                    icon: const Icon(Icons.delete_sweep_rounded),
                    onPressed: () {
                      setState(() {
                        AppLogger.clear();
                      });
                    },
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: logs.isEmpty
                      ? const Center(
                          child: Text(
                            'Belum ada log tercatat.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : SelectionArea(
                          child: ListView.builder(
                            itemCount: logs.length,
                            itemBuilder: (context, index) {
                              final line = logs[index];
                              final isError = line.contains('[ERROR]');
                              final isWarn = line.contains('[WARN]');
                              final color = isError
                                  ? Colors.redAccent
                                  : isWarn
                                      ? Colors.orangeAccent
                                      : Colors.greenAccent;

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  line,
                                  style: TextStyle(
                                    color: color,
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.icon(
                    onPressed: logs.isEmpty
                        ? null
                        : () {
                            Clipboard.setData(
                              ClipboardData(text: AppLogger.exportLogs()),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Seluruh log berhasil disalin ke clipboard!',
                                ),
                              ),
                            );
                          },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Salin Seluruh Log'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
