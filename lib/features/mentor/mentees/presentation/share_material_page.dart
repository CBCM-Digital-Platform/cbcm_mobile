import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../messaging/data/temporary_contacts.dart';
import '../../../messaging/domain/message_models.dart';

abstract class MaterialSharingRepository {
  /// The real version uploads the file and links it to the mentees once the
  /// backend has an upload endpoint and a way to share with specific people.
  Future<void> share({
    required String fileName,
    required int sizeBytes,
    required List<int> menteeIds,
    String note = '',
  });
}

/// MOCKED: nothing is sent anywhere yet.
class MockMaterialSharingRepository implements MaterialSharingRepository {
  @override
  Future<void> share({
    required String fileName,
    required int sizeBytes,
    required List<int> menteeIds,
    String note = '',
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));
    debugPrint('[SHARE] (mock) $fileName ($sizeBytes bytes) -> $menteeIds');
  }
}

final materialSharingRepositoryProvider =
    Provider<MaterialSharingRepository>((ref) => MockMaterialSharingRepository());

class ShareMaterialPage extends ConsumerStatefulWidget {
  const ShareMaterialPage({super.key, this.initialMentee});

  final MessageUser? initialMentee;

  @override
  ConsumerState<ShareMaterialPage> createState() => _ShareMaterialPageState();
}

class _ShareMaterialPageState extends ConsumerState<ShareMaterialPage> {
  PlatformFile? _file;
  int _fileSize = 0;
  late final Set<int> _selected = {
    if (widget.initialMentee != null) widget.initialMentee!.id,
  };
  final _note = TextEditingController();
  bool _sharing = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  String _size(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _pick() async {
    final file = await FilePicker.pickFile();
    if (file == null) return;
    final size = await file.length();
    if (!mounted) return;
    setState(() {
      _file = file;
      _fileSize = size ?? 0;
    });
  }

  Future<void> _share() async {
    final file = _file;
    if (file == null || _selected.isEmpty || _sharing) return;

    setState(() => _sharing = true);
    try {
      await ref.read(materialSharingRepositoryProvider).share(
            fileName: file.name,
            sizeBytes: _fileSize,
            menteeIds: _selected.toList(),
            note: _note.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Material "${file.name}" shared successfully!'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _sharing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not share. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mentees = ref.watch(contactsProvider);
    final canShare = _file != null && _selected.isNotEmpty && !_sharing;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Share material'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.pageIndicator.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Preview: nothing is sent yet. Sharing connects when the '
              'backend upload endpoint is ready.',
              style: TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),
          const Text('File', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pick,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    _file == null ? Icons.upload_file : Icons.insert_drive_file,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _file == null
                          ? 'Choose a file (PDF, video, audio...)'
                          : '${_file!.name}  •  ${_size(_fileSize)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Share with', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          if (mentees.isEmpty) const Text('No mentees yet.'),
          for (final m in mentees)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.primary,
              value: _selected.contains(m.id),
              title: Text(m.fullName),
              onChanged: (v) => setState(() {
                if (v == true) {
                  _selected.add(m.id);
                } else {
                  _selected.remove(m.id);
                }
              }),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add a note (optional)',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: _sharing ? 'Sharing...' : 'Share',
              onPressed: canShare ? _share : null,
            ),
          ),
        ],
      ),
    );
  }
}