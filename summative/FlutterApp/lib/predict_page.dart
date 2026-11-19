import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api.dart';
import 'theme.dart';

/// One input of the model: the API field name, what the user sees, and what is allowed.
class InputSpec {
  const InputSpec(this.key, this.label, this.hint, {this.helper, this.min, this.max, this.options});

  final String key; // field name the API expects
  final String label;
  final String hint;
  final String? helper;
  final int? min; // whole-number fields have a range...
  final int? max;
  final List<String>? options; // ...text fields have a list of allowed values

  bool get isNumber => options == null;
}

const states = [
  'Abia',
  'Adamawa',
  'Akwa Ibom',
  'Anambra',
  'Bauchi',
  'Bayelsa',
  'Benue',
  'Borno',
  'Cross River',
  'Delta',
  'Ebonyi',
  'Edo',
  'Ekiti',
  'Enugu',
  'FCT',
  'Gombe',
  'Imo',
  'Jigawa',
  'Kaduna',
  'Kano',
  'Katsina',
  'Kebbi',
  'Kogi',
  'Kwara',
  'Lagos',
  'Nasarawa',
  'Niger',
  'Ogun',
  'Ondo',
  'Osun',
  'Oyo',
  'Plateau',
  'Rivers',
  'Sokoto',
  'Taraba',
  'Yobe',
  'Zamfara',
];

/// The 12 inputs, grouped the way an owner would answer them.
const sections = <String, List<InputSpec>>{
  'Location and sector': [
    InputSpec('state', 'State', 'e.g. Lagos', helper: 'Any of the 36 states or FCT', options: states),
    InputSpec('urban', 'Area', 'Urban or Rural', options: ['Urban', 'Rural']),
    InputSpec(
      'sector',
      'Sector',
      'e.g. Services',
      helper: 'Agriculture, Manufacturing, Services or Other',
      options: ['Agriculture', 'Manufacturing', 'Services', 'Other'],
    ),
    InputSpec('survey_year', 'Year', '2019 to 2024', min: 2019, max: 2024),
  ],
  'The business': [
    InputSpec('total_workers', 'Total workers', '1 to 56', helper: 'Including the owner', min: 1, max: 56),
    InputSpec('business_age', 'Business age (years)', '1 to 77', min: 1, max: 77),
    InputSpec('separate_premises', 'Has its own premises', '1 = yes, 0 = no', min: 0, max: 1),
    InputSpec('sells_to_firms_or_govt', 'Sells to firms or government', '1 = yes, 0 = no', min: 0, max: 1),
    InputSpec(
      'credit_difficulty',
      'Struggled to get credit (last 12 months)',
      '1 = yes, 0 = no',
      min: 0,
      max: 1,
    ),
  ],
  'The owner': [
    InputSpec('owner_education_years', 'Years of schooling', '0 to 18', min: 0, max: 18),
    InputSpec(
      'owner_age_group',
      'Age group',
      '1 to 6',
      helper: '1 = 15-24, 2 = 25-34, 3 = 35-44, 4 = 45-54, 5 = 55-64, 6 = 65+',
      min: 1,
      max: 6,
    ),
    InputSpec('owner_female', 'Owner is a woman', '1 = yes, 0 = no', min: 0, max: 1),
  ],
};

/// The example from Swagger, so the demo can be filled in one tap.
const example = {
  'state': 'Lagos',
  'urban': 'Urban',
  'sector': 'Services',
  'survey_year': '2024',
  'total_workers': '2',
  'business_age': '6',
  'separate_premises': '1',
  'sells_to_firms_or_govt': '0',
  'credit_difficulty': '1',
  'owner_education_years': '12',
  'owner_age_group': '3',
  'owner_female': '1',
};

class PredictPage extends StatefulWidget {
  const PredictPage({super.key});

  @override
  State<PredictPage> createState() => _PredictPageState();
}

class _PredictPageState extends State<PredictPage> {
  final _formKey = GlobalKey<FormState>();
  final _resultKey = GlobalKey();
  final _specs = sections.values.expand((group) => group).toList();
  late final _controllers = {for (final spec in _specs) spec.key: TextEditingController()};

  bool _loading = false;
  Prediction? _prediction;
  String? _error;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Text fields accept any capitalisation ("lagos"), but the API needs the exact name ("Lagos").
  String? _matchOption(InputSpec spec, String text) {
    for (final option in spec.options!) {
      if (option.toLowerCase() == text.trim().toLowerCase()) return option;
    }
    return null;
  }

  String? _validate(InputSpec spec, String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Required';
    if (!spec.isNumber) {
      return _matchOption(spec, text) == null ? 'Not recognised. ${spec.helper ?? spec.hint}' : null;
    }
    final number = int.tryParse(text);
    if (number == null) return 'Enter a whole number';
    if (number < spec.min! || number > spec.max!) return 'Must be between ${spec.min} and ${spec.max}';
    return null;
  }

  Future<void> _predict() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _prediction = null;
        _error = 'Some fields need fixing. Check the messages in red above.';
      });
      _showResult();
      return;
    }

    // Build the JSON body: numbers as int, text fields as the exact allowed value.
    final inputs = <String, Object>{
      for (final spec in _specs)
        spec.key: spec.isNumber
            ? int.parse(_controllers[spec.key]!.text.trim())
            : _matchOption(spec, _controllers[spec.key]!.text)!,
    };

    setState(() {
      _loading = true;
      _error = null;
      _prediction = null;
    });
    try {
      final prediction = await predict(inputs, {for (final spec in _specs) spec.key: spec.label});
      setState(() => _prediction = prediction);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    _showResult();
  }

  /// Scrolls so the result card is on screen after the button is pressed.
  void _showResult() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _resultKey.currentContext;
      if (target != null && target.mounted) {
        Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 320), curve: Curves.easeOut);
      }
    });
  }

  void _fillExample() {
    for (final entry in example.entries) {
      _controllers[entry.key]!.text = entry.value;
    }
    _formKey.currentState?.validate();
  }

  void _clear() {
    for (final controller in _controllers.values) {
      controller.clear();
    }
    _formKey.currentState?.reset();
    setState(() {
      _prediction = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          // SingleChildScrollView (not ListView) keeps all 12 fields built even when scrolled off
          // screen, so Form.validate() checks every one of them.
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Header(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _loading ? null : _fillExample,
                      icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                      label: const Text('Fill example'),
                    ),
                    TextButton.icon(
                      onPressed: _loading ? null : _clear,
                      icon: const Icon(Icons.restart_alt_rounded, size: 18),
                      label: const Text('Clear'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final section in sections.entries) ...[
                  _Section(
                    title: section.key,
                    children: [
                      for (final spec in section.value)
                        TextFormField(
                          controller: _controllers[spec.key],
                          enabled: !_loading,
                          decoration: InputDecoration(
                            labelText: spec.label,
                            hintText: spec.hint,
                            // The hint disappears once there is a value, so the range or meaning
                            // ("1 = yes, 0 = no") also stays visible under the field.
                            helperText: spec.helper ?? spec.hint,
                            helperMaxLines: 2,
                            errorMaxLines: 2,
                          ),
                          keyboardType: spec.isNumber ? TextInputType.number : TextInputType.text,
                          inputFormatters: spec.isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (value) => _validate(spec, value),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                FilledButton(
                  onPressed: _loading ? null : _predict,
                  child: _loading
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.white),
                        )
                      : const Text('Predict'),
                ),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      'The first request can take up to a minute while the free server wakes up.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.slate, fontSize: 13),
                    ),
                  ),
                const SizedBox(height: 16),
                KeyedSubtree(
                  key: _resultKey,
                  child: _ResultArea(prediction: _prediction, error: _error),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(24)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.azure, AppColors.azureDeep],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.storefront_rounded, color: AppColors.white, size: 30),
          SizedBox(height: 14),
          Text(
            'Revenue Estimator',
            style: TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.w700, height: 1.2),
          ),
          SizedBox(height: 6),
          Text(
            'Estimate the monthly revenue per worker of a Nigerian informal business, '
            'so a lender can size a loan it can afford.',
            style: TextStyle(color: AppColors.azureMist, fontSize: 14, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppTheme.cardRadius,
        border: Border.all(color: AppColors.cloud),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink),
          ),
          for (final child in children) ...[const SizedBox(height: 14), child],
        ],
      ),
    );
  }
}

/// The one area that shows either the prediction or a readable error.
class _ResultArea extends StatelessWidget {
  const _ResultArea({required this.prediction, required this.error});

  final Prediction? prediction;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (error != null) {
      content = _box(
        key: const ValueKey('error'),
        background: AppColors.crimsonMist,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: AppColors.crimson, size: 20),
              SizedBox(width: 8),
              Text(
                'Could not predict',
                style: TextStyle(color: AppColors.crimson, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(error!, style: const TextStyle(color: AppColors.crimson, height: 1.45)),
        ],
      );
    } else if (prediction != null) {
      final p = prediction!;
      content = _box(
        key: ValueKey(p),
        background: AppColors.azureMist,
        children: [
          const Text(
            'Estimated revenue per worker',
            style: TextStyle(color: AppColors.azureDeep, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '${money(p.perWorker)} / month',
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Whole business: ${money(p.wholeBusiness)} / month',
            style: const TextStyle(color: AppColors.ink, fontSize: 15, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          Text(
            'PPP-adjusted US dollars. Model: ${p.model}. '
            'A typical estimate is within about 2.8 times the real value, so treat it as a guide, not a fact.',
            style: const TextStyle(color: AppColors.slate, fontSize: 12.5, height: 1.45),
          ),
        ],
      );
    } else {
      content = _box(
        key: const ValueKey('empty'),
        background: AppColors.snow,
        children: const [Text('Your estimate will appear here.', style: TextStyle(color: AppColors.slate))],
      );
    }
    return AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: content);
  }

  Widget _box({required Key key, required Color background, required List<Widget> children}) => Container(
    key: key,
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: background, borderRadius: AppTheme.cardRadius),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );
}

/// 1376.14 -> "$1,376.14"
String money(double value) {
  final parts = value.toStringAsFixed(2).split('.');
  final whole = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return '\$$whole.${parts[1]}';
}
