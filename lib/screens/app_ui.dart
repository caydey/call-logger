import 'package:call_log/call_log.dart';
import 'package:flutter/material.dart';
import 'package:logger/screens/About/about.dart';
import 'package:logger/screens/Analytics/analytics.dart';
import 'package:logger/screens/Home/home.dart';
import 'package:logger/screens/Settings/settings.dart';
import 'package:logger/screens/manager.dart';
import 'package:logger/utils/analytics_fns.dart';
import 'package:logger/utils/filters.dart';
import 'package:logger/utils/snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApplicationUi extends StatefulWidget {
  final Future<void> Function()? refresher;
  final SharedPreferences? preferences;
  const ApplicationUi({
    super.key,
    required this.entries,
    required this.refresher,
    required this.preferences,
  });

  final Iterable<CallLogEntry>? entries;

  @override
  State<ApplicationUi> createState() => _ApplicationUiState();
}

class _ApplicationUiState extends State<ApplicationUi> {
  late Iterable<CallLogEntry>? currentLogs;
  bool isProcessing = false;
  bool areFiltersApplied = false;
  bool shouldShowLinearLoader = false;
  String linearLoaderText = "";

  late bool isDurationFilteringEnabled;
  late bool isConfirmBeforeDownloadEnabled;
  late bool isSharingDisabled;
  late String currentImportType;

  // Logs filters
  Map logFilters = {
    "specific_ph": false,
    "phone_to_match": "",
    "selected_call_types": [...CallType.values],
    "date_range_op": "All Time",
    "start_date": DateTime.now(),
    "end_date": DateTime.now(),
    "min_duration": "0",
    "max_duration": null,
    "duration_filtering": false,
  };

  void filterLogs(Map filters) async {
    setState(() {
      isProcessing = true;
    });

    try {
      var selectedCallTypes = filters["selected_call_types"] as List<CallType>;
      var phoneToMatch = filters["phone_to_match"] as String;
      var shouldUseSpecificPhoneNumber = filters["specific_ph"] as bool;
      var dateRangeOption = filters["date_range_op"] as String;
      var startDate = filters["start_date"] as DateTime;
      var endDate = filters["end_date"] as DateTime;
      var shouldUseDurationFiltering = filters["duration_filtering"] as bool;
      var minDuration = filters["min_duration"] as String?;
      var maxDuration = filters["max_duration"] as String?;

      logFilters["start_date"] = startDate;
      logFilters["end_date"] = endDate;
      logFilters["date_range_op"] = dateRangeOption;
      logFilters["specific_ph"] = shouldUseSpecificPhoneNumber;
      logFilters["phone_to_match"] = phoneToMatch;
      logFilters["selected_call_types"] = [...selectedCallTypes];
      logFilters['duration_filtering'] = shouldUseDurationFiltering;
      logFilters['min_duration'] = minDuration;
      logFilters['max_duration'] = maxDuration;

      var filteredLogs = await Filters.filterLogs(widget.entries, logFilters);

      if (areInitalFilters()) {
        setState(() {
          areFiltersApplied = false;
          currentLogs = filteredLogs;
          isProcessing = false;
        });
      } else {
        setState(() {
          areFiltersApplied = true;
          currentLogs = filteredLogs;
          isProcessing = false;
        });
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.show(context, content: "Filter error");
      }
      setState(() {
        areFiltersApplied = false;
        currentLogs = widget.entries;
        isProcessing = false;
      });
    }
  }

  bool areInitalFilters() {
    return Filters.compareFilterMasks({
      "specific_ph": false,
      "phone_to_match": "",
      "selected_call_types": [...CallType.values],
      "date_range_op": "All Time",
      "start_date": DateTime.now(),
      "end_date": DateTime.now(),
      "min_duration": "0",
      "max_duration": null,
      "duration_filtering": false,
    }, logFilters);
  }

  void removeLogFilters() {
    if (areInitalFilters()) return;

    setState(() {
      areFiltersApplied = false;
      logFilters = {
        "specific_ph": false,
        "phone_to_match": "",
        "selected_call_types": [...CallType.values],
        "date_range_op": "All Time",
        "start_date": DateTime.now(),
        "end_date": DateTime.now(),
        "min_duration": "0",
        "max_duration": null,
        "duration_filtering": false,
      };
      currentLogs = widget.entries;
    });
  }

  void showLinearProgressLoader({String waitingMessage = ""}) {
    setState(() {
      shouldShowLinearLoader = true;
      linearLoaderText = waitingMessage;
    });
  }

  void hideLinearProgressLoader() {
    setState(() {
      shouldShowLinearLoader = false;
      linearLoaderText = "";
    });
  }

  Future<bool?> setDurationFilteringState(bool newState) async {
    var saved =
        await widget.preferences?.setBool("duration_filtering", newState);
    setState(() {
      if (saved != null && saved) {
        isDurationFilteringEnabled = newState;
      }
    });
    return saved;
  }

  Future<bool?> setConfirmBeforeDownloadingState(bool newState) async {
    var saved = await widget.preferences?.setBool("confirm_download", newState);
    setState(() {
      if (saved != null && saved) {
        isConfirmBeforeDownloadEnabled = newState;
      }
    });
    return saved;
  }

  Future<bool?> setShareButtonState(bool newState) async {
    var saved = await widget.preferences?.setBool("sharing", newState);
    setState(() {
      if (saved != null && saved) {
        isSharingDisabled = newState;
      }
    });
    return saved;
  }

  Future<bool?> setCurrentImportType(String newState) async {
    var saved = await widget.preferences?.setString("import_type", newState);
    setState(() {
      if (saved != null && saved) {
        currentImportType = newState;
      }
    });
    return saved;
  }

  void showLoader() {
    setState(() {
      isProcessing = true;
    });
  }

  void hideLoader() {
    setState(() {
      isProcessing = false;
    });
  }

  @override
  void initState() {
    super.initState();
    currentLogs = widget.entries;

    isDurationFilteringEnabled =
        widget.preferences?.getBool("duration_filtering") ?? false;
    isConfirmBeforeDownloadEnabled =
        widget.preferences?.getBool("confirm_download") ?? false;
    isSharingDisabled = widget.preferences?.getBool("sharing") ?? false;
    currentImportType = widget.preferences?.getString("import_type") ?? "csv";
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ScreenManager(
          initialIndex: 0,
          canFilterUsingDuration: isDurationFilteringEnabled,
          currentFilters: logFilters,
          logs: currentLogs,
          areFiltersApplied: areFiltersApplied,
          filterLogs: filterLogs,
          removeLogFilters: removeLogFilters,
          askForDownloadConfirmation: isConfirmBeforeDownloadEnabled,
          showSharingButton: !isSharingDisabled,
          currentImportType: currentImportType,
          items: <Screen>[
            Screen(
              index: 0,
              label: "Logs",
              icon: Icons.call_outlined,
              selectedIcon: Icons.call,
              screen: HomeScreen(
                entries: currentLogs,
                refreshEntries: widget.refresher,
              ),
            ),
            Screen(
              index: 1,
              label: "Analytics",
              icon: Icons.pie_chart_outline,
              selectedIcon: Icons.pie_chart,
              screen: AnalyticsScreen(
                entries: currentLogs,
                currentCallTypes:
                    logFilters["selected_call_types"] as List<CallType>,
                analyzer: CallLogAnalyzer(
                    logs: currentLogs ?? const Iterable.empty()),
              ),
            ),
            Screen(
              label: "Settings",
              index: 2,
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
              screen: SettingsScreen(
                showLoader: showLoader,
                hideLoader: hideLoader,
                showLinearProgressLoader: showLinearProgressLoader,
                hideLinearProgressLoader: hideLinearProgressLoader,
                refresher: widget.refresher,
                initialDurationFilteringState: isDurationFilteringEnabled,
                initialConfirmBeforeDownloadState:
                    isConfirmBeforeDownloadEnabled,
                initialSharingState: isSharingDisabled,
                initialImportTypeState: currentImportType,
                setCurrentImportType: setCurrentImportType,
                setDurationFilteringState: setDurationFilteringState,
                setConfirmBeforeDownloadingState:
                    setConfirmBeforeDownloadingState,
                setShareButtonState: setShareButtonState,
              ),
            ),
            const Screen(
              label: "About",
              index: 3,
              icon: Icons.info_outline,
              selectedIcon: Icons.info,
              screen: AboutScreen(),
            ),
          ],
        ),
        if (shouldShowLinearLoader)
          Material(
            color: Colors.transparent,
            child: Container(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color.fromARGB(202, 0, 0, 0)
                  : const Color.fromARGB(202, 255, 255, 255),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          linearLoaderText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18.0,
                          ),
                        ),
                        const SizedBox(
                          height: 10.0,
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 15),
                          width: MediaQuery.of(context).size.width / 2,
                          // height: 20,
                          child: ClipRRect(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(10)),
                            child: LinearProgressIndicator(
                              backgroundColor: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color.fromARGB(255, 96, 82, 118)
                                  : const Color.fromARGB(255, 214, 189, 255),
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color.fromARGB(255, 203, 169, 255)
                                  : const Color.fromARGB(255, 106, 26, 227),
                            ),
                          ),
                        )
                      ]),
                ),
              ),
            ),
          ),
        if (isProcessing)
          Container(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black38
                : Colors.white38,
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color.fromARGB(255, 203, 169, 255)
                    : const Color.fromARGB(255, 106, 26, 227),
              ),
            ),
          ),
      ],
    );
  }
}
