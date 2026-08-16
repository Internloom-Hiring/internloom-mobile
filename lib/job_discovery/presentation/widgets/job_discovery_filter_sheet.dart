import 'package:flutter/material.dart';

import '../../data/models/job_discovery_filters.dart';
import 'internloom_brand.dart';

class JobDiscoveryFilterSheet extends StatefulWidget {
  const JobDiscoveryFilterSheet({
    super.key,
    required this.initialFilters,
  });

  final JobDiscoveryFilters initialFilters;

  @override
  State<JobDiscoveryFilterSheet> createState() =>
      _JobDiscoveryFilterSheetState();
}

class _JobDiscoveryFilterSheetState extends State<JobDiscoveryFilterSheet> {
  late final TextEditingController _locationController;
  late final TextEditingController _ctcController;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(
      text: widget.initialFilters.location,
    );
    _ctcController = TextEditingController(
      text: widget.initialFilters.ctc,
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    _ctcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Filter jobs',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: InternloomColors.ink,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Clear',
                  onPressed: () {
                    _locationController.clear();
                    _ctcController.clear();
                  },
                  icon: const Icon(
                    Icons.clear_all,
                    color: InternloomColors.bookTeal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'e.g. Bangalore, WFH, Paris',
                prefixIcon: Icon(
                  Icons.location_on_outlined,
                  color: InternloomColors.bookTeal,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: InternloomColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: InternloomColors.leafGreen,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctcController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _apply(context),
              decoration: const InputDecoration(
                labelText: 'CTC',
                hintText: 'Text contains, e.g. 10 or LPA',
                prefixIcon: Icon(
                  Icons.payments_outlined,
                  color: InternloomColors.bookTeal,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: InternloomColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: InternloomColors.leafGreen,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Both filters use text contains matching because the production '
              'columns are stored as text.',
              style: TextStyle(color: InternloomColors.muted),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: InternloomColors.leafGreen,
                  foregroundColor: InternloomColors.white,
                ),
                onPressed: () => _apply(context),
                child: const Text('Apply filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _apply(BuildContext context) {
    Navigator.of(context).pop(
      JobDiscoveryFilters(
        location: _locationController.text,
        ctc: _ctcController.text,
      ),
    );
  }
}
