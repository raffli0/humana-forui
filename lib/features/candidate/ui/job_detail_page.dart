import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/services/file_picker_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../home/ui/profile_page.dart';
import '../../../core/widgets/skeleton.dart';
import '../models/recruitment_model.dart';
import '../services/application_service.dart';

class JobDetailPage extends StatefulWidget {
  final RecruitmentModel job;

  const JobDetailPage({super.key, required this.job});

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  final ApplicationService _applicationService = ApplicationService();
  final FilePickerService _filePickerService = FilePickerService();

  bool _isLoading = true; // Start as true for initial check
  bool _hasApplied = false;
  String? _applicationStatus;
  String? _appliedResumeUrl;
  File? _selectedDocument;
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
    _checkApplicationStatus();
  }

  Future<void> _checkApplicationStatus() async {
    final authState = context.read<AuthBloc>().state;
    if (authState.user == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final application = await _applicationService.getMyApplication(
        authState.user!.id,
      );

      if (mounted) {
        setState(() {
          final app = application;
          _hasApplied = app != null && app.jobId == widget.job.id;
          if (_hasApplied && app != null) {
            _applicationStatus = app.status;
            _appliedResumeUrl = app.resumeUrl;
            if (_appliedResumeUrl != null) {
              _selectedFileName = _appliedResumeUrl!.split('/').last;
              // Remove query params if any (Supabase URLs often have them)
              if (_selectedFileName!.contains('?')) {
                _selectedFileName = _selectedFileName!.split('?').first;
              }
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickDocument() async {
    try {
      final file = await _filePickerService.pickDocument();
      if (file != null && mounted) {
        setState(() {
          _selectedDocument = file;
          _selectedFileName = _filePickerService.getFileName(file.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memilih file: $e')));
      }
    }
  }

  Future<void> _applyForJob() async {
    final authState = context.read<AuthBloc>().state;
    if (authState.user == null) return;

    // Check profile completeness
    if (authState.user!.phone == null || authState.user!.phone!.isEmpty) {
      _showProfileIncompleteDialog();
      return;
    }

    // Check if document is selected
    if (_selectedDocument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan upload dokumen pendukung terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Upload document first
      final documentUrl = await _filePickerService.uploadDocument(
        file: _selectedDocument!,
        candidateId: authState.user!.id,
        jobId: widget.job.id,
      );

      // Submit application with document URL
      await _applicationService.submitApplication(
        jobId: widget.job.id,
        candidateId: authState.user!.id,
        documentUrl: documentUrl,
      );

      if (mounted) {
        setState(() {
          _hasApplied = true;
          _applicationStatus = 'Applied';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lamaran berhasil dikirim!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengirim lamaran: $e')));
      }
    }
  }

  void _showProfileIncompleteDialog() {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(
          'Profile Belum Lengkap',
          style: TextStyle(color: colors.textPrimary),
        ),
        content: Text(
          'Untuk melamar pekerjaan, Anda harus melengkapi profile terlebih dahulu.\n\nInformasi yang diperlukan:\n• Nomor Telepon',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Lengkapi Profile'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colors.background,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail Lowongan',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const _JobDetailSkeleton()
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colors.border.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.job.title,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.job.companyName,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.job.department} • ${widget.job.location}',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildTag(widget.job.type, Colors.blue, colors),
                            if (widget.job.salaryRange.isNotEmpty)
                              _buildTag(
                                widget.job.salaryRange,
                                Colors.green,
                                colors,
                              ),
                            _buildTag(
                              'Posted ${DateFormat.yMMMd().format(widget.job.createdAt)}',
                              Colors.grey,
                              colors,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Description Section
                  _buildSection(
                    'Deskripsi Pekerjaan',
                    widget.job.description.isNotEmpty
                        ? widget.job.description
                        : 'Tidak ada deskripsi',
                    colors,
                  ),

                  // Requirements Section
                  _buildSection(
                    'Persyaratan',
                    widget.job.requirements.isNotEmpty
                        ? widget.job.requirements
                        : 'Tidak ada persyaratan khusus',
                    colors,
                  ),

                  // Document Upload Section
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colors.border.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dokumen Pendukung',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _hasApplied
                              ? 'Dokumen yang Anda kirimkan untuk lamaran ini.'
                              : 'Upload CV/Resume Anda (PDF, DOC, DOCX - Max 5MB)',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_selectedFileName != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (_hasApplied)
                                        const Text(
                                          'Sudah Terupload',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      Text(
                                        _selectedFileName!,
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                if (!_hasApplied)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _selectedDocument = null;
                                        _selectedFileName = null;
                                      });
                                    },
                                  ),
                              ],
                            ),
                          )
                        else if (!_hasApplied)
                          OutlinedButton.icon(
                            onPressed: _pickDocument,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Pilih Dokumen'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.accent,
                              side: BorderSide(color: colors.accent),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: _hasApplied
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Sudah Melamar - Status: ${_applicationStatus ?? "Applied"}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : ElevatedButton(
                  onPressed: _isLoading ? null : _applyForJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Lamar Sekarang',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, AppColors colors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color color, AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _JobDetailSkeleton extends StatelessWidget {
  const _JobDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(height: 28, width: 250),
                SizedBox(height: 12),
                Skeleton(height: 18, width: 150),
                SizedBox(height: 8),
                Skeleton(height: 14, width: 200),
                SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Skeleton(height: 24, width: 80, borderRadius: 8),
                    Skeleton(height: 24, width: 100, borderRadius: 8),
                    Skeleton(height: 24, width: 120, borderRadius: 8),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Skeleton(height: 22, width: 180),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                Skeleton(height: 14, width: double.infinity),
                SizedBox(height: 8),
                Skeleton(height: 14, width: double.infinity),
                SizedBox(height: 8),
                Skeleton(height: 14, width: 250),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Skeleton(height: 22, width: 150),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                Skeleton(height: 14, width: double.infinity),
                SizedBox(height: 8),
                Skeleton(height: 14, width: double.infinity),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
