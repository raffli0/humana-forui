import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../candidate/models/recruitment_model.dart';
import '../../candidate/services/recruitment_service.dart';
import '../../../core/widgets/skeleton.dart';
import 'job_detail_page.dart';

class JobListPage extends StatefulWidget {
  const JobListPage({super.key});

  @override
  State<JobListPage> createState() => _JobListPageState();
}

class _JobListPageState extends State<JobListPage> {
  final RecruitmentService _service = RecruitmentService();
  List<RecruitmentModel> _jobs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    setState(() => _isLoading = true);
    try {
      final jobs = await _service.fetchJobs(
        query: _searchQuery,
        type: _selectedType,
      );
      if (mounted) {
        setState(() {
          _jobs = jobs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading jobs: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colors.background,
        title: Text(
          'Lowongan Pekerjaan',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false, // Managed by bottom nav
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Cari posisi, departemen...',
                hintStyle: TextStyle(color: colors.textSecondary),
                prefixIcon: Icon(Icons.search, color: colors.textSecondary),
                filled: true,
                fillColor: colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                _searchQuery = value;
                _fetchJobs();
              },
            ),
          ),

          // Filters (Simple Chips)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Semua',
                  isSelected: _selectedType == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedType = null;
                    });
                    _fetchJobs();
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Full-time',
                  isSelected: _selectedType == 'Full-time',
                  onSelected: (selected) {
                    setState(() {
                      _selectedType = 'Full-time';
                    });
                    _fetchJobs();
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Contract',
                  isSelected: _selectedType == 'Contract',
                  onSelected: (selected) {
                    setState(() {
                      _selectedType = 'Contract';
                    });
                    _fetchJobs();
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Part-time',
                  isSelected: _selectedType == 'Part-time',
                  onSelected: (selected) {
                    setState(() {
                      _selectedType = 'Part-time';
                    });
                    _fetchJobs();
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Internship',
                  isSelected: _selectedType == 'Internship',
                  onSelected: (selected) {
                    setState(() {
                      _selectedType = 'Internship';
                    });
                    _fetchJobs();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Job List
          Expanded(
            child: _isLoading
                ? ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 5,
                    itemBuilder: (context, index) => const _JobSkeleton(),
                  )
                : _jobs.isEmpty
                ? Center(
                    child: Text(
                      'Tidak ada lowongan ditemukan',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _jobs.length,
                    itemBuilder: (context, index) {
                      final job = _jobs[index];
                      return _JobCard(job: job);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function(bool) onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: colors.surface,
      selectedColor: colors.accent.withValues(alpha: 0.2),
      checkmarkColor: colors.accent,
      labelStyle: TextStyle(
        color: isSelected ? colors.accent : colors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? colors.accent
              : colors.border.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final RecruitmentModel job;

  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Card(
      elevation: 0,
      color: colors.surface,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => JobDetailPage(job: job)),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        job.title.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: colors.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job.companyName,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${job.department} • ${job.location}',
                          style: TextStyle(
                            color: colors.textSecondary.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _Tag(label: job.type, color: Colors.blue),
                  const SizedBox(width: 8),
                  if (job.salaryRange.isNotEmpty)
                    _Tag(label: job.salaryRange, color: Colors.green),
                  const Spacer(),
                  if (context.read<AuthBloc>().state.user?.jobId == job.id)
                    const _Tag(label: 'Sudah Dilamar', color: Colors.green),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Posted ${DateFormat.yMMMd().format(job.createdAt)}',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                  Text(
                    'Lihat Detail',
                    style: TextStyle(
                      color: colors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
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

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

class _JobSkeleton extends StatelessWidget {
  const _JobSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      elevation: 0,
      color: colors.surface,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Skeleton(height: 48, width: 48, borderRadius: 12),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton(height: 18, width: 200),
                      SizedBox(height: 8),
                      Skeleton(height: 14, width: 120),
                      SizedBox(height: 4),
                      Skeleton(height: 12, width: 150),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Skeleton(height: 24, width: 80, borderRadius: 8),
                SizedBox(width: 8),
                Skeleton(height: 24, width: 100, borderRadius: 8),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Skeleton(height: 12, width: 100),
                Skeleton(height: 14, width: 80),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
