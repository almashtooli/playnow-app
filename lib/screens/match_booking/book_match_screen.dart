import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/ui_helpers.dart';
import '../../l10n/app_localizations.dart';
import '../../models/session_models.dart';
import '../../models/venue_models.dart';
import '../../services/match_booking_service.dart';
import '../../theme/app_theme.dart';

class BookMatchScreen extends StatefulWidget {
  final Venue venue;
  final List<Pitch> pitches;

  const BookMatchScreen({
    super.key,
    required this.venue,
    required this.pitches,
  });

  @override
  State<BookMatchScreen> createState() => _BookMatchScreenState();
}

class _BookMatchScreenState extends State<BookMatchScreen> {
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Pitch? _selectedPitch;
  int _teamsCount = 1;   // 1 = training, 2 = full match
  int _teamSize = 5;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.pitches.isNotEmpty) _selectedPitch = widget.pitches.first;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (ctx, child) => child!,
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (_startTime ?? const TimeOfDay(hour: 18, minute: 0))
          : (_endTime ?? const TimeOfDay(hour: 19, minute: 0)),
      builder: (ctx, child) => child!,
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startTime = picked;
        else _endTime = picked;
      });
    }
  }

  DateTime _combine(DateTime date, TimeOfDay time) =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

  Future<void> _submit() async {
    if (_selectedPitch == null) {
      UiHelpers.showWarning(context, 'Please select a pitch');
      return;
    }
    if (_selectedDate == null || _startTime == null || _endTime == null) {
      UiHelpers.showWarning(context, 'Please select a date and time');
      return;
    }

    final startsAt = _combine(_selectedDate!, _startTime!);
    final endsAt = _combine(_selectedDate!, _endTime!);

    if (!endsAt.isAfter(startsAt)) {
      UiHelpers.showWarning(context, 'End time must be after start time');
      return;
    }

    final confirmed = await UiHelpers.confirm(
      context,
      title: 'Confirm Booking Request',
      message:
          'Send a ${_teamsCount == 2 ? 'full match' : 'training'} request to ${widget.venue.name}?\n\n'
          'Pitch: ${_selectedPitch!.name}\n'
          'Date: ${_formatDate(startsAt)}\n'
          'Time: ${_fmt(startsAt)} – ${_fmt(endsAt)}\n'
          'Teams: $_teamsCount × $_teamSize players',
      confirmText: 'Send Request',
      confirmColor: context.primary,
    );
    if (!confirmed || !mounted) return;

    setState(() => _loading = true);
    try {
      await context.read<MatchBookingService>().create(
            pitchId: _selectedPitch!.id,
            teamsCount: _teamsCount,
            teamSize: _teamSize,
            startsAt: startsAt,
            endsAt: endsAt,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );
      if (!mounted) return;
      UiHelpers.showSuccess(
          context, 'Request sent! The venue will review and respond.');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) UiHelpers.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.bookAMatch,
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Venue'),
              _venueCard(),
              const SizedBox(height: 20),
              _sectionLabel(l.selectPitch),
              _pitchSelector(),
              const SizedBox(height: 20),
              _sectionLabel('Booking Type'),
              _bookingTypeSelector(),
              const SizedBox(height: 20),
              _sectionLabel(l.playersPerTeam),
              _teamSizeSelector(),
              const SizedBox(height: 20),
              _sectionLabel('Date & Time'),
              _dateTimePicker(),
              const SizedBox(height: 20),
              _sectionLabel(l.notesOptional),
              _notesField(),
              const SizedBox(height: 32),
              _submitButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: context.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
      );

  Widget _venueCard() => Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecor(),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.greenTint,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.greenBorder, width: 0.5),
              ),
              child: Icon(Icons.stadium_rounded, color: context.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.venue.name,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: context.textPrimary)),
                Text(widget.venue.city,
                    style: TextStyle(fontSize: 12, color: context.textSecondary)),
              ],
            ),
          ],
        ),
      );

  Widget _pitchSelector() {
    if (widget.pitches.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecor(),
        child: Text('No pitches available',
            style: TextStyle(color: context.textSecondary)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _cardDecor(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Pitch>(
          isExpanded: true,
          value: _selectedPitch,
          onChanged: (p) => setState(() => _selectedPitch = p),
          items: widget.pitches
              .map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(p.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _bookingTypeSelector() {
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        _typeChip(
          label: l.teamTraining,
          icon: Icons.sports_soccer_rounded,
          subtitle: '1 team',
          value: 1,
        ),
        const SizedBox(width: 12),
        _typeChip(
          label: l.fullMatch,
          icon: Icons.emoji_events_rounded,
          subtitle: '2 teams vs each other',
          value: 2,
        ),
      ],
    );
  }

  Widget _typeChip({
    required String label,
    required IconData icon,
    required String subtitle,
    required int value,
  }) {
    final selected = _teamsCount == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _teamsCount = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? context.greenTint : context.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? context.greenBorder : context.borderColor,
              width: selected ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected ? context.primary : context.textHint,
                  size: 28),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: selected ? context.primary : context.textPrimary)),
              Text(subtitle,
                  style: TextStyle(fontSize: 11, color: context.textHint)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamSizeSelector() => Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecor(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$_teamSize players per team',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14),
            ),
            Row(
              children: [
                _counterBtn(Icons.remove_rounded,
                    () => setState(() => _teamSize = (_teamSize - 1).clamp(2, 30))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('$_teamSize',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 18)),
                ),
                _counterBtn(Icons.add_rounded,
                    () => setState(() => _teamSize = (_teamSize + 1).clamp(2, 30))),
              ],
            ),
          ],
        ),
      );

  Widget _counterBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: context.greenTint,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.greenBorder, width: 0.5),
          ),
          child: Icon(icon, color: context.primary, size: 18),
        ),
      );

  Widget _dateTimePicker() {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecor(),
      child: Column(
        children: [
          _dateRow(),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(child: _timeRow(l.startTime, _startTime, () => _pickTime(true))),
              const SizedBox(width: 12),
              Expanded(child: _timeRow(l.endTime, _endTime, () => _pickTime(false))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateRow() => GestureDetector(
        onTap: _pickDate,
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: context.primary, size: 18),
            const SizedBox(width: 10),
            Text(
              _selectedDate != null
                  ? _formatDate(_selectedDate!)
                  : AppLocalizations.of(context).selectDate,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: _selectedDate != null
                      ? context.textPrimary
                      : context.textHint),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: context.textHint),
          ],
        ),
      );

  Widget _timeRow(String label, TimeOfDay? time, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: context.scaffoldBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.borderColor, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 11, color: context.textSecondary)),
              const SizedBox(height: 2),
              Text(
                time != null ? time.format(context) : '--:--',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: time != null
                        ? context.textPrimary
                        : context.textHint),
              ),
            ],
          ),
        ),
      );

  Widget _notesField() => Container(
        decoration: _cardDecor(),
        child: TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Any special requests or info for the venue...',
            hintStyle: TextStyle(color: context.textHint, fontSize: 13),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      );

  Widget _submitButton() => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 16),
          ),
          child: _loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onPrimary))
              : Text(AppLocalizations.of(context).submitBooking),
        ),
      );

  BoxDecoration _cardDecor() => BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor, width: 0.5),
      );

  String _formatDate(DateTime dt) {
    return '${dt.day} ${AppLocalizations.of(context).shortMonth(dt.month)} ${dt.year}';
  }

  String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
