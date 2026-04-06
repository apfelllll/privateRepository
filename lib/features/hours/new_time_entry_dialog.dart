import 'package:doordesk/core/theme/app_theme.dart';
import 'package:doordesk/core/widgets/door_desk_form_card.dart';
import 'package:doordesk/core/widgets/labeled_text_form_field.dart';
import 'package:doordesk/models/assigned_order.dart';
import 'package:doordesk/providers/door_desk_providers.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Öffnet den Dialog „Neue Arbeitszeiterfassung“ (Auftrag, Zeiten, Pause).
Future<void> showNewTimeEntryDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => const _NewTimeEntryDialog(),
  );
}

enum _OverlayKind { none, date, time }

/// Fixe Auswahlliste „Tätigkeit“ im Formular.
const _activityOptions = <String>[
  'Bankraum',
  'Maschinenraum',
  'Lackraum',
  'Montage',
  'Planung',
];

IconData _activityIcon(String activity) {
  return switch (activity) {
    'Bankraum' => Icons.table_restaurant_rounded,
    'Maschinenraum' => Icons.precision_manufacturing_rounded,
    'Lackraum' => Icons.format_color_fill_rounded,
    'Montage' => Icons.handyman_rounded,
    'Planung' => Icons.design_services_rounded,
    _ => Icons.work_outline_rounded,
  };
}

/// Gleiche äußere Maße für Auftrags-, Tätigkeits- und Zeitauswahl-Popover.
const double _kPickerPopoverWidth = 400;
const double _kPickerPopoverHeight = 380;

/// Breite der Karte „Neue Arbeitszeiterfassung“ (ohne Rand zum Bildschirmrand).
const double _kNewTimeEntryFormWidth = 620;

enum _TimeTarget { start, end, pause }

class _NewTimeEntryDialog extends ConsumerStatefulWidget {
  const _NewTimeEntryDialog();

  @override
  ConsumerState<_NewTimeEntryDialog> createState() =>
      _NewTimeEntryDialogState();
}

class _NewTimeEntryDialogState extends ConsumerState<_NewTimeEntryDialog> {
  /// Kalendertag, für den die Erfassung gilt (ohne Uhrzeit).
  DateTime _workDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  AssignedOrder? _orderFromList;
  late final TextEditingController _orderSearch;
  late final FocusNode _orderFocus;
  late final TextEditingController _activitySearch;
  late final FocusNode _activityFocus;
  String? _activityFromList;
  TimeOfDay? _start;
  TimeOfDay? _end;

  /// Pausendauer: Stunden- und Minutenanteil (0–12 h, 0–59 min).
  ({int hours, int minutes}) _pause = (hours: 0, minutes: 0);

  late final TextEditingController _descriptionController;

  _OverlayKind _overlay = _OverlayKind.none;
  _TimeTarget? _timeTarget;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _orderSearch = TextEditingController();
    _orderFocus = FocusNode();
    _activitySearch = TextEditingController();
    _activityFocus = FocusNode();
    _orderSearch.addListener(_onOrderSearchChanged);
    _activitySearch.addListener(_onActivitySearchChanged);
  }

  @override
  void dispose() {
    _orderSearch.removeListener(_onOrderSearchChanged);
    _activitySearch.removeListener(_onActivitySearchChanged);
    _orderSearch.dispose();
    _orderFocus.dispose();
    _activitySearch.dispose();
    _activityFocus.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onOrderSearchChanged() {
    final p = _orderFromList;
    if (p != null && p.title.trim() != _orderSearch.text.trim()) {
      setState(() => _orderFromList = null);
    }
  }

  void _onActivitySearchChanged() {
    final p = _activityFromList;
    if (p != null && p.trim() != _activitySearch.text.trim()) {
      setState(() => _activityFromList = null);
    }
  }

  Iterable<AssignedOrder> _orderOptions(
    TextEditingValue value,
    List<AssignedOrder> orders,
  ) {
    if (orders.isEmpty) {
      return const Iterable<AssignedOrder>.empty();
    }
    final q = value.text.trim().toLowerCase();
    if (q.isEmpty) {
      return orders;
    }
    return orders.where(
      (o) => o.title.toLowerCase().contains(q),
    );
  }

  Iterable<String> _activityOptionsForQuery(TextEditingValue value) {
    final q = value.text.trim().toLowerCase();
    if (q.isEmpty) return _activityOptions;
    return _activityOptions.where((a) => a.toLowerCase().contains(q));
  }

  AssignedOrder? _resolveOrder(String fieldText, List<AssignedOrder> orders) {
    final t = fieldText.trim();
    if (t.isEmpty) return null;

    if (_orderFromList != null && _orderFromList!.title.trim() == t) {
      return _orderFromList;
    }

    final lower = t.toLowerCase();
    final exact = orders
        .where((o) => o.title.trim().toLowerCase() == lower)
        .toList();
    if (exact.length == 1) return exact.first;

    final contains = orders
        .where((o) => o.title.toLowerCase().contains(lower))
        .toList();
    if (contains.length == 1) return contains.first;

    return null;
  }

  void _closeOverlay() {
    setState(() {
      _overlay = _OverlayKind.none;
      _timeTarget = null;
    });
  }

  static String _twoDigits(int n) => n.toString().padLeft(2, '0');

  static String _formatTime(TimeOfDay t) =>
      '${_twoDigits(t.hour)}:${_twoDigits(t.minute)}';

  static String _formatPause(({int hours, int minutes}) p) =>
      '${_twoDigits(p.hours)}:${_twoDigits(p.minutes)}';

  String _formatWorkDate() => DateFormat.yMMMMd('de_DE').format(_workDate);

  void _openDateOverlay() {
    setState(() => _overlay = _OverlayKind.date);
  }

  void _openTimeOverlay(_TimeTarget target) {
    setState(() {
      _overlay = _OverlayKind.time;
      _timeTarget = target;
    });
  }

  ({int hour, int minute}) _initialTimeForTarget(_TimeTarget target) {
    switch (target) {
      case _TimeTarget.start:
        final t = _start ?? TimeOfDay.now();
        return (hour: t.hour, minute: t.minute);
      case _TimeTarget.end:
        final t = _end ?? _start ?? TimeOfDay.now();
        return (hour: t.hour, minute: t.minute);
      case _TimeTarget.pause:
        return (hour: _pause.hours, minute: _pause.minutes);
    }
  }

  ({String title, int hourCount, String? subtitle}) _configForTimeTarget(
    _TimeTarget target,
  ) {
    return switch (target) {
      _TimeTarget.start => (
        title: 'Arbeitsbeginn',
        hourCount: 24,
        subtitle: null,
      ),
      _TimeTarget.end => (title: 'Arbeitsende', hourCount: 24, subtitle: null),
      _TimeTarget.pause => (
        title: 'Pause',
        hourCount: 13,
        subtitle: 'Dauer der Pause',
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orders = ref.watch(assignedOrdersProvider).value ??
        <AssignedOrder>[];
    final screenH = MediaQuery.sizeOf(context).height;
    final screenW = MediaQuery.sizeOf(context).width;
    final contentHeight = (screenH * 0.62).clamp(420.0, 620.0);
    final formCardWidth = _kNewTimeEntryFormWidth > screenW - 32
        ? screenW - 32
        : _kNewTimeEntryFormWidth;

    final formCard = DoorDeskFormCard(
      child: SizedBox(
        width: formCardWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Text(
                'Neue Arbeitszeiterfassung',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: SizedBox(
                height: contentHeight,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DoorDeskPickField(
                        labelText: 'Datum',
                        helperText: null,
                        value: _formatWorkDate(),
                        hint: 'Datum wählen',
                        suffixIcon: Icons.calendar_today_outlined,
                        onTap: _openDateOverlay,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: RawAutocomplete<AssignedOrder>(
                              focusNode: _orderFocus,
                              textEditingController: _orderSearch,
                              displayStringForOption: (o) => o.title,
                              optionsBuilder: (value) =>
                                  _orderOptions(value, orders),
                              onSelected: (o) {
                                setState(() {
                                  _orderFromList = o;
                                  _orderSearch.text = o.title;
                                });
                              },
                              fieldViewBuilder:
                                  (context, controller, focusNode, onFieldSubmitted) {
                                return LabeledFormBlock(
                                  label: 'Auftrag',
                                  child: doorDeskInputFieldTheme(
                                    context,
                                    TextField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      textInputAction: TextInputAction.next,
                                      onSubmitted: (_) =>
                                          onFieldSubmitted(),
                                      decoration: doorDeskFormInputDecoration(
                                        context,
                                        hintText: orders.isEmpty
                                            ? 'Keine Aufträge vorhanden'
                                            : 'Auftrag suchen oder aus Liste wählen…',
                                      ),
                                    ),
                                  ),
                                );
                              },
                              optionsViewBuilder:
                                  (context, onSelected, options) {
                                if (options.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    elevation: 8,
                                    borderRadius: BorderRadius.circular(12),
                                    color: theme.colorScheme.surface,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxHeight: 280,
                                      ),
                                      child: ListView.builder(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        itemCount: options.length,
                                        itemBuilder: (context, index) {
                                          final o = options.elementAt(index);
                                          return ListTile(
                                            leading: Icon(
                                              Icons.assignment_outlined,
                                              color: theme.colorScheme.primary,
                                            ),
                                            title: Text(o.title),
                                            onTap: () => onSelected(o),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: RawAutocomplete<String>(
                              focusNode: _activityFocus,
                              textEditingController: _activitySearch,
                              displayStringForOption: (a) => a,
                              optionsBuilder: _activityOptionsForQuery,
                              onSelected: (a) {
                                setState(() {
                                  _activityFromList = a;
                                  _activitySearch.text = a;
                                });
                              },
                              fieldViewBuilder:
                                  (context, controller, focusNode, onFieldSubmitted) {
                                return LabeledFormBlock(
                                  label: 'Tätigkeit',
                                  child: doorDeskInputFieldTheme(
                                    context,
                                    TextField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      textInputAction: TextInputAction.next,
                                      onSubmitted: (_) => onFieldSubmitted(),
                                      decoration: doorDeskFormInputDecoration(
                                        context,
                                        hintText:
                                            'Tätigkeit suchen oder aus Liste wählen…',
                                      ),
                                    ),
                                  ),
                                );
                              },
                              optionsViewBuilder:
                                  (context, onSelected, options) {
                                if (options.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    elevation: 8,
                                    borderRadius: BorderRadius.circular(12),
                                    color: theme.colorScheme.surface,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxHeight: 280,
                                      ),
                                      child: ListView.builder(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        itemCount: options.length,
                                        itemBuilder: (context, index) {
                                          final a = options.elementAt(index);
                                          return ListTile(
                                            leading: Icon(
                                              _activityIcon(a),
                                              color: theme.colorScheme.primary,
                                            ),
                                            title: Text(a),
                                            onTap: () => onSelected(a),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _DoorDeskPickField(
                              labelText: 'Arbeitsbeginn',
                              helperText: null,
                              value: _start == null
                                  ? null
                                  : _formatTime(_start!),
                              hint: 'Zeit wählen',
                              suffixIcon: Icons.schedule_outlined,
                              onTap: () => _openTimeOverlay(_TimeTarget.start),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _DoorDeskPickField(
                              labelText: 'Arbeitsende',
                              helperText: null,
                              value: _end == null ? null : _formatTime(_end!),
                              hint: 'Zeit wählen',
                              suffixIcon: Icons.schedule_outlined,
                              onTap: () => _openTimeOverlay(_TimeTarget.end),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _DoorDeskPickField(
                        labelText: 'Pause',
                        helperText: null,
                        value: _formatPause(_pause),
                        hint: 'Dauer wählen',
                        suffixIcon: Icons.schedule_outlined,
                        onTap: () => _openTimeOverlay(_TimeTarget.pause),
                      ),
                      const SizedBox(height: 20),
                      LabeledTextFormField(
                        label: 'Beschreibung',
                        subtitle: 'Beschreibung der Tätigkeit',
                        controller: _descriptionController,
                        hint: 'Optional',
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Abbrechen'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final resolved = _resolveOrder(_orderSearch.text, orders);
                      if (resolved == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Bitte einen Auftrag aus der Liste wählen oder so eingeben, '
                              'dass genau ein Treffer zugeordnet werden kann.',
                            ),
                          ),
                        );
                        return;
                      }
                      Navigator.of(context).pop();
                    },
                    child: const Text('Speichern'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: SizedBox(
        width: screenW,
        height: screenH,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            Center(child: formCard),
            if (_overlay != _OverlayKind.none)
              _FullScreenPopoverScrim(
                onDismiss: _closeOverlay,
                child: switch (_overlay) {
                  _OverlayKind.date => _buildDatePickerPopover(),
                  _OverlayKind.time => _buildTimePickerPopover(),
                  _OverlayKind.none => const SizedBox.shrink(),
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerPopover() {
    return _DatePickerBody(
      key: ValueKey<String>(
        '${_workDate.year}-${_workDate.month}-${_workDate.day}',
      ),
      initialDate: _workDate,
      onCancel: _closeOverlay,
      onConfirm: (d) {
        setState(() {
          _workDate = DateTime(d.year, d.month, d.day);
          _overlay = _OverlayKind.none;
        });
      },
    );
  }

  Widget _buildTimePickerPopover() {
    final target = _timeTarget!;
    final cfg = _configForTimeTarget(target);
    final initial = _initialTimeForTarget(target);
    return _ScrollTimePickerBody(
      key: ValueKey<Object>('${target}_${initial.hour}_${initial.minute}'),
      title: cfg.title,
      subtitle: cfg.subtitle,
      initialHour: initial.hour.clamp(0, cfg.hourCount - 1),
      initialMinute: initial.minute.clamp(0, 59),
      hourCount: cfg.hourCount,
      minuteLabel: 'Min.',
      onCancel: _closeOverlay,
      onConfirm: (t) {
        setState(() {
          switch (target) {
            case _TimeTarget.start:
              _start = t;
            case _TimeTarget.end:
              _end = t;
            case _TimeTarget.pause:
              _pause = (hours: t.hour, minutes: t.minute);
          }
          _overlay = _OverlayKind.none;
          _timeTarget = null;
        });
      },
    );
  }
}

/// Vollflächige Abdunkelung (gesamter Dialog/Fenster-Bereich) + Popover in der Mitte.
class _FullScreenPopoverScrim extends StatelessWidget {
  const _FullScreenPopoverScrim({required this.onDismiss, required this.child});

  final VoidCallback onDismiss;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scrim = Theme.of(context).colorScheme.shadow.withValues(alpha: 0.45);

    return Positioned.fill(
      child: GestureDetector(
        onTap: onDismiss,
        behavior: HitTestBehavior.opaque,
        child: ColoredBox(
          color: scrim,
          child: Center(
            child: GestureDetector(onTap: () {}, child: child),
          ),
        ),
      ),
    );
  }
}

/// Nur-Lese-[TextField] im DoorDesk-Formularstil (Auswahl per Overlay).
class _DoorDeskPickField extends StatefulWidget {
  const _DoorDeskPickField({
    required this.labelText,
    this.helperText,
    required this.value,
    required this.hint,
    required this.suffixIcon,
    required this.onTap,
  });

  final String labelText;
  final String? helperText;

  /// Zeileninhalt; leer oder null → [hint] als Hint.
  final String? value;
  final String hint;
  final IconData suffixIcon;
  final VoidCallback onTap;

  @override
  State<_DoorDeskPickField> createState() => _DoorDeskPickFieldState();
}

class _DoorDeskPickFieldState extends State<_DoorDeskPickField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  bool get _isEmpty {
    final v = widget.value;
    return v == null || v.isEmpty || v == '—';
  }

  String get _text => _isEmpty ? '' : widget.value!;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _text);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _DoorDeskPickField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final t = _text;
    if (_controller.text != t) {
      _controller.value = TextEditingValue(
        text: t,
        selection: TextSelection.collapsed(offset: t.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LabeledFormBlock(
      label: widget.labelText,
      subtitle: widget.helperText,
      child: doorDeskInputFieldTheme(
        context,
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          readOnly: true,
          mouseCursor: SystemMouseCursors.click,
          onTap: () {
            _focusNode.requestFocus();
            widget.onTap();
          },
          minLines: 1,
          maxLines: widget.helperText != null ? 3 : 1,
          decoration: doorDeskFormInputDecoration(
            context,
            hintText: _isEmpty ? widget.hint : null,
            suffixIcon: Icon(
              widget.suffixIcon,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

/// Ermöglicht Ziehen mit der Maus am Rad (nicht nur Mausrad) — u. a. für Windows.
class _WheelScrollBehavior extends MaterialScrollBehavior {
  const _WheelScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };
}

/// Eine Spalte: Beschriftung + Rad — [labels] laufen endlos (zyklisch).
class _TimeWheelColumn extends StatelessWidget {
  const _TimeWheelColumn({
    super.key,
    required this.label,
    required this.labels,
    required this.controller,
    required this.onSelectedItemChanged,
    required this.itemExtent,
    this.looping = true,
  });

  final String label;
  final List<String> labels;
  final FixedExtentScrollController controller;
  final ValueChanged<int> onSelectedItemChanged;
  final double itemExtent;
  final bool looping;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlightFill = theme.colorScheme.primaryContainer.withValues(
      alpha: 0.42,
    );
    final highlightBorder = theme.colorScheme.primary;

    final textStyle = theme.textTheme.titleMedium;
    final children = labels
        .map(
          (s) => Center(
            child: Text(
              s,
              style: textStyle?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        )
        .toList();

    final delegate = looping
        ? ListWheelChildLoopingListDelegate(children: children)
        : ListWheelChildListDelegate(children: children);

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ScrollConfiguration(
                behavior: const _WheelScrollBehavior(),
                child: ListWheelScrollView.useDelegate(
                  controller: controller,
                  itemExtent: itemExtent,
                  perspective: 0.005,
                  diameterRatio: 1.35,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (i) {
                    if (looping) {
                      onSelectedItemChanged(i % labels.length);
                    } else if (i >= 0 && i < labels.length) {
                      onSelectedItemChanged(i);
                    }
                  },
                  childDelegate: delegate,
                ),
              ),
              IgnorePointer(
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: itemExtent,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: highlightFill,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: highlightBorder, width: 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Datum (Tag · Monat · Jahr) — gleiche Rad-UX wie bei der Uhrzeit.
class _DatePickerBody extends StatefulWidget {
  const _DatePickerBody({
    super.key,
    required this.initialDate,
    required this.onCancel,
    required this.onConfirm,
  });

  final DateTime initialDate;
  final VoidCallback onCancel;
  final void Function(DateTime date) onConfirm;

  @override
  State<_DatePickerBody> createState() => _DatePickerBodyState();
}

class _DatePickerBodyState extends State<_DatePickerBody> {
  static const _itemExtent = 36.0;
  static const _yearCount = 21;
  static const _yearsBeforeCenter = 10;

  late int _yearBase;
  late int _workYear;
  late int _workMonth;
  late int _workDay;
  late FixedExtentScrollController _yearCtrl;
  late FixedExtentScrollController _monthCtrl;
  late FixedExtentScrollController _dayCtrl;

  List<String> get _yearLabels =>
      List.generate(_yearCount, (i) => '${_yearBase + i}');

  List<String> get _monthLabels =>
      List.generate(12, (i) => '${i + 1}'.padLeft(2, '0'));

  List<String> _dayLabels() {
    final cap = DateTime(_workYear, _workMonth + 1, 0).day;
    return List.generate(cap, (i) => '${i + 1}'.padLeft(2, '0'));
  }

  void _afterMonthOrYearChange() {
    final cap = DateTime(_workYear, _workMonth + 1, 0).day;
    if (_workDay > cap) _workDay = cap;
    _dayCtrl.dispose();
    _dayCtrl = FixedExtentScrollController(initialItem: _workDay - 1);
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _yearBase = now.year - _yearsBeforeCenter;
    final d = widget.initialDate;
    _workYear = d.year.clamp(_yearBase, _yearBase + _yearCount - 1);
    _workMonth = d.month;
    _workDay = d.day;
    final cap = DateTime(_workYear, _workMonth + 1, 0).day;
    _workDay = _workDay.clamp(1, cap);

    _yearCtrl = FixedExtentScrollController(initialItem: _workYear - _yearBase);
    _monthCtrl = FixedExtentScrollController(initialItem: _workMonth - 1);
    _dayCtrl = FixedExtentScrollController(initialItem: _workDay - 1);
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    _monthCtrl.dispose();
    _dayCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surface,
      child: SizedBox(
        width: _kPickerPopoverWidth,
        height: _kPickerPopoverHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Datum wählen',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gültigkeit der Arbeitszeiterfassung',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Center(
                child: SizedBox(
                  height: 200,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _TimeWheelColumn(
                          label: 'Tag',
                          key: ValueKey<int>(
                            Object.hash(_workYear, _workMonth),
                          ),
                          labels: _dayLabels(),
                          controller: _dayCtrl,
                          itemExtent: _itemExtent,
                          looping: false,
                          onSelectedItemChanged: (i) =>
                              setState(() => _workDay = i + 1),
                        ),
                      ),
                      Expanded(
                        child: _TimeWheelColumn(
                          label: 'Monat',
                          labels: _monthLabels,
                          controller: _monthCtrl,
                          itemExtent: _itemExtent,
                          onSelectedItemChanged: (slot) {
                            setState(() {
                              _workMonth = slot + 1;
                              _afterMonthOrYearChange();
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: _TimeWheelColumn(
                          label: 'Jahr',
                          labels: _yearLabels,
                          controller: _yearCtrl,
                          itemExtent: _itemExtent,
                          onSelectedItemChanged: (slot) {
                            setState(() {
                              _workYear = _yearBase + slot;
                              _afterMonthOrYearChange();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: widget.onCancel,
                    child: const Text('Abbrechen'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      widget.onConfirm(
                        DateTime(_workYear, _workMonth, _workDay),
                      );
                    },
                    child: const Text('Speichern'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Scroll-Auswahl Stunden/Minuten — als kompaktes Popover im Formular.
class _ScrollTimePickerBody extends StatefulWidget {
  const _ScrollTimePickerBody({
    super.key,
    required this.title,
    required this.initialHour,
    required this.initialMinute,
    required this.hourCount,
    required this.minuteLabel,
    required this.onCancel,
    required this.onConfirm,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final int initialHour;
  final int initialMinute;
  final int hourCount;
  final String minuteLabel;
  final VoidCallback onCancel;
  final void Function(TimeOfDay value) onConfirm;

  @override
  State<_ScrollTimePickerBody> createState() => _ScrollTimePickerBodyState();
}

class _ScrollTimePickerBodyState extends State<_ScrollTimePickerBody> {
  static const _itemExtent = 40.0;

  /// 12 Slots: 00, 05, …, 55
  static final _minuteLabels = List.generate(
    12,
    (i) => (i * 5).toString().padLeft(2, '0'),
  );

  late int _hour;
  late int _minute;
  late FixedExtentScrollController _hourCtrl;
  late FixedExtentScrollController _minuteCtrl;

  /// Arbeitszeit auf 5 Min runden; [maxPauseHour] z. B. 12 für Pausen-Rad (sonst Uhr 0–23).
  static (int, int) _roundToFiveMinutes(
    int hour,
    int minute, {
    required int? maxPauseHour,
  }) {
    final raw = hour * 60 + minute;
    var rounded = ((raw + 2) ~/ 5) * 5;
    if (maxPauseHour != null) {
      final cap = maxPauseHour * 60 + 55;
      if (rounded > cap) rounded = cap;
    } else {
      rounded %= 24 * 60;
    }
    return (rounded ~/ 60, rounded % 60);
  }

  List<String> get _hourLabels =>
      List.generate(widget.hourCount, (i) => i.toString().padLeft(2, '0'));

  @override
  void initState() {
    super.initState();
    final isPause = widget.hourCount == 13;
    final (rh, rm) = _roundToFiveMinutes(
      widget.initialHour,
      widget.initialMinute,
      maxPauseHour: isPause ? 12 : null,
    );
    _hour = rh.clamp(0, widget.hourCount - 1);
    _minute = rm;
    _hourCtrl = FixedExtentScrollController(initialItem: _hour);
    _minuteCtrl = FixedExtentScrollController(initialItem: _minute ~/ 5);
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surface,
      child: SizedBox(
        width: _kPickerPopoverWidth,
        height: _kPickerPopoverHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Center(
                child: SizedBox(
                  height: 200,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _TimeWheelColumn(
                          label: 'Stunden',
                          labels: _hourLabels,
                          controller: _hourCtrl,
                          itemExtent: _itemExtent,
                          onSelectedItemChanged: (i) =>
                              setState(() => _hour = i % widget.hourCount),
                        ),
                      ),
                      Expanded(
                        child: _TimeWheelColumn(
                          label: widget.minuteLabel,
                          labels: _minuteLabels,
                          controller: _minuteCtrl,
                          itemExtent: _itemExtent,
                          onSelectedItemChanged: (i) =>
                              setState(() => _minute = (i % 12) * 5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: widget.onCancel,
                    child: const Text('Abbrechen'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      widget.onConfirm(TimeOfDay(hour: _hour, minute: _minute));
                    },
                    child: const Text('Speichern'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
