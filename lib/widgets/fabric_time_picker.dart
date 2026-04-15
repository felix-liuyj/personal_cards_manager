import 'package:flutter/material.dart';
import 'package:personal_cards_manager/core/theme/fabric_theme.dart';

/// 织物风格时间选择器
class FabricTimePicker {
  /// 显示时间选择器
  static Future<TimeOfDay?> showTimePicker({
    required BuildContext context,
    required TimeOfDay initialTime,
    String? title,
  }) async {
    int selectedHour = initialTime.hour;
    int selectedMinute = initialTime.minute;

    return await showDialog<TimeOfDay>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 标题
                    Text(
                      title ?? '选择时间',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // 时间显示
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: FabricTheme.denim.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: FabricTheme.denim.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTimeUnit(
                            context,
                            selectedHour.toString().padLeft(2, '0'),
                            '时',
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              ':',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: FabricTheme.denim,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          _buildTimeUnit(
                            context,
                            selectedMinute.toString().padLeft(2, '0'),
                            '分',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 小时选择
                    _buildHourSelector(
                      context,
                      selectedHour,
                      (hour) => setState(() => selectedHour = hour),
                    ),

                    const SizedBox(height: 16),

                    // 分钟选择
                    _buildMinuteSelector(
                      context,
                      selectedMinute,
                      (minute) => setState(() => selectedMinute = minute),
                    ),

                    const SizedBox(height: 24),

                    // 按钮
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            '取消',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(
                              context,
                              TimeOfDay(
                                hour: selectedHour,
                                minute: selectedMinute,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FabricTheme.denim,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('确定'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildTimeUnit(
    BuildContext context,
    String value,
    String unit,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: FabricTheme.denim,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: FabricTheme.thread),
        ),
      ],
    );
  }

  static Widget _buildHourSelector(
    BuildContext context,
    int selectedHour,
    Function(int) onHourChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '小时',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: FabricTheme.thread),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 24,
            itemBuilder: (context, index) {
              final isSelected = index == selectedHour;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => onHourChanged(index),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 50,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? FabricTheme.denim
                          : FabricTheme.canvas.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? FabricTheme.denim
                            : Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      index.toString().padLeft(2, '0'),
                      style: TextStyle(
                        color: isSelected ? Colors.white : FabricTheme.thread,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static Widget _buildMinuteSelector(
    BuildContext context,
    int selectedMinute,
    Function(int) onMinuteChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '分钟',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: FabricTheme.thread),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 12,
            itemBuilder: (context, index) {
              final minute = index * 5;
              final isSelected = minute == selectedMinute;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => onMinuteChanged(minute),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 50,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? FabricTheme.denim
                          : FabricTheme.canvas.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? FabricTheme.denim
                            : Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      minute.toString().padLeft(2, '0'),
                      style: TextStyle(
                        color: isSelected ? Colors.white : FabricTheme.thread,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
