use crate::config::BatteryConfig;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub(crate) enum BatteryAction {
    Low,
    Critical,
    Suspend,
}

#[derive(Default)]
pub(crate) struct BatteryMonitor {
    low_notified: bool,
    critical_notified: bool,
    suspended: bool,
}

impl BatteryMonitor {
    pub(crate) fn update(
        &mut self,
        level: Option<u8>,
        charging: bool,
        config: &BatteryConfig,
    ) -> Vec<BatteryAction> {
        let Some(level) = level else {
            return Vec::new();
        };
        if charging {
            self.low_notified = false;
            self.critical_notified = false;
            self.suspended = false;
            return Vec::new();
        }

        if level > config.low {
            self.low_notified = false;
        }
        if level > config.critical {
            self.critical_notified = false;
        }
        if level > config.suspend {
            self.suspended = false;
        }

        let mut actions = Vec::new();
        if level <= config.critical && !self.critical_notified {
            actions.push(BatteryAction::Critical);
            self.critical_notified = true;
            self.low_notified = true;
        } else if level <= config.low && !self.low_notified {
            actions.push(BatteryAction::Low);
            self.low_notified = true;
        }
        if config.automatic_suspend && level <= config.suspend && !self.suspended {
            actions.push(BatteryAction::Suspend);
            self.suspended = true;
        }
        actions
    }
}

#[cfg(test)]
mod tests {
    use super::{BatteryAction, BatteryMonitor};
    use crate::config::BatteryConfig;

    #[test]
    fn warns_at_thresholds_and_only_once_until_charged() {
        let mut monitor = BatteryMonitor::default();
        let config = BatteryConfig::default();
        assert_eq!(
            monitor.update(Some(19), false, &config),
            [BatteryAction::Low]
        );
        assert!(monitor.update(Some(18), false, &config).is_empty());
        assert_eq!(
            monitor.update(Some(5), false, &config),
            [BatteryAction::Critical]
        );
        assert!(monitor.update(Some(4), false, &config).is_empty());
        assert!(monitor.update(Some(4), true, &config).is_empty());
        assert_eq!(
            monitor.update(Some(19), false, &config),
            [BatteryAction::Low]
        );
    }

    #[test]
    fn automatic_suspend_is_optional_and_once_per_low_battery_cycle() {
        let mut monitor = BatteryMonitor::default();
        let config = BatteryConfig {
            automatic_suspend: false,
            ..BatteryConfig::default()
        };
        assert!(
            !monitor
                .update(Some(3), false, &config)
                .contains(&BatteryAction::Suspend)
        );
        let mut suspend_monitor = BatteryMonitor::default();
        let config = BatteryConfig::default();
        assert_eq!(
            suspend_monitor.update(Some(3), false, &config),
            [BatteryAction::Critical, BatteryAction::Suspend]
        );
        assert!(suspend_monitor.update(Some(3), false, &config).is_empty());
    }
}
