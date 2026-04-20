import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../models/session_models.dart';
import '../../models/venue_models.dart';
import '../../services/dashboard_service.dart';
import '../../theme/app_theme.dart';

class CreateSessionScreen extends StatefulWidget {
  final Venue venue;
  const CreateSessionScreen({super.key, required this.venue});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  final DashboardService _service = DashboardService();
  List<Pitch> _pitches = [];
  Pitch? _selectedPitch;
  DateTime? _startTime;
  DateTime? _endTime;
  final _maxPlayersController = TextEditingController(text: '10');
  final _priceController = TextEditingController(text: '15');
  bool _loading = false;
  bool _loadingPitches = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPitches();
  }

  @override
  void dispose() {
    _maxPlayersController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadPitches() async {
    try {
      final json = await apiClient.get(
        '/pitches',
        queryParams: {'venueId': widget.venue.id.toString()},
      );
      final List data = json['data'] ?? json;
      if (!mounted) return;
      setState(() {
        _pitches = data.map((e) => Pitch.fromJson(e)).toList();
        if (_pitches.isNotEmpty) _selectedPitch = _pitches.first;
        _loadingPitches = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingPitches = false;
        _error = e.message;
      });
    }
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !mounted) return;

    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() => isStart ? _startTime = dt : _endTime = dt);
  }

  Future<void> _create() async {
    if (_selectedPitch == null || _startTime == null || _endTime == null) {
      setState(() => _error = 'Please fill all fields');
      return;
    }
    if (_endTime!.isBefore(_startTime!)) {
      setState(() => _error = 'End time must be after start time');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _service.createSession(
        pitchId: _selectedPitch!.id,
        startsAt: _startTime!.toUtc().toIso8601String(),
        endsAt: _endTime!.toUtc().toIso8601String(),
        maxPlayers: int.tryParse(_maxPlayersController.text) ?? 10,
        pricePerPlayer: double.tryParse(_priceController.text) ?? 15,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  String _formatDt(DateTime? dt) => dt == null
      ? AppLocalizations.of(context).selectDate
      : DateFormat('EEE, MMM d • h:mm a').format(dt);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).createSession),
      ),
      body: _loadingPitches
          ? Center(child: CircularProgressIndicator(color: context.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Pitch selector
                  _SectionLabel('Pitch'),
                  Container(
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.borderColor, width: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButton<Pitch>(
                      isExpanded: true,
                      underline: const SizedBox(),
                      value: _selectedPitch,
                      hint: const Text('Select pitch'),
                      items: _pitches
                          .map(
                            (p) =>
                                DropdownMenuItem(value: p, child: Text(p.name)),
                          )
                          .toList(),
                      onChanged: (p) => setState(() => _selectedPitch = p),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Start time
                  _SectionLabel(AppLocalizations.of(context).startTime),
                  _TimeTile(
                    label: _formatDt(_startTime),
                    icon: Icons.play_circle_outline,
                    onTap: () => _pickDateTime(isStart: true),
                  ),
                  const SizedBox(height: 12),

                  // End time
                  _SectionLabel(AppLocalizations.of(context).endTime),
                  _TimeTile(
                    label: _formatDt(_endTime),
                    icon: Icons.stop_circle_outlined,
                    onTap: () => _pickDateTime(isStart: false),
                  ),
                  const SizedBox(height: 16),

                  // Max players
                  _SectionLabel(AppLocalizations.of(context).maxPlayers),
                  _InputField(
                    controller: _maxPlayersController,
                    hint: '10',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // Price
                  _SectionLabel(AppLocalizations.of(context).pricePerPlayer),
                  _InputField(
                    controller: _priceController,
                    hint: '15',
                    keyboardType: TextInputType.number,
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: TextStyle(color: context.errorColor)),
                  ],
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _loading ? null : _create,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.onPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            AppLocalizations.of(context).createSession,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    ),
  );
}

class _TimeTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _TimeTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: context.primary),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 15)),
        ],
      ),
    ),
  );
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  const _InputField({
    required this.controller,
    required this.hint,
    required this.keyboardType,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: context.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.borderColor, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.borderColor, width: 0.5),
      ),
    ),
  );
}
