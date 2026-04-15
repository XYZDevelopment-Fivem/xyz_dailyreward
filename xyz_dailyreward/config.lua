Config = {}

Config.Title = 'XYZ DAILY REWARD'
Config.Subtitle = 'Advanced Daily Reward System'
Config.Command = 'dailyreward'
Config.OpenKey = 'F7'
Config.ThemeAccent = '#8a2bff'
Config.ThemeAccent2 = '#aa62ff'
Config.UseUTC = false
Config.MonthDays = 30
Config.RequestCooldownMs = 1000
Config.ClaimCooldownMs = 1500
Config.TokenLifetimeSeconds = 45
Config.RequireOneByOneClaim = true
Config.AllowCatchupClaims = false
Config.LogMenuOpen = true
Config.LogClaims = true
Config.LogSuspicious = true

-- Config.Webhook = 'server/server_config.lua'

Config.Rewards = {
    [1] = {
        label = 'Starter Cash',
        rewards = {
            { type = 'item', name = 'money', count = 5000 }
        }
    },
    [2] = {
        label = 'Food Pack',
        rewards = {
            { type = 'item', name = 'bread', count = 5 }
        }
    },
    [3] = {
        label = 'Water Pack',
        rewards = {
            { type = 'item', name = 'water', count = 5 }
        }
    },
    [4] = {
        label = 'Medical Pack',
        rewards = {
            { type = 'item', name = 'bandage', count = 2 }
        }
    },
    [5] = {
        label = 'Ammo Pack',
        rewards = {
            { type = 'item', name = 'ammo-9', count = 24 }
        }
    },
    [6] = {
        label = 'Repair Kit',
        rewards = {
            { type = 'item', name = 'repairkit', count = 1 }
        }
    },
    [7] = {
        label = 'Weekly Cash',
        rewards = {
            { type = 'item', name = 'money', count = 10000 }
        }
    },
    [8] = {
        label = 'Supply Pack',
        rewards = {
            { type = 'item', name = 'bread', count = 3 },
            { type = 'item', name = 'water', count = 3 }
        }
    },
    [9] = {
        label = 'Medical Pack',
        rewards = {
            { type = 'item', name = 'bandage', count = 3 }
        }
    },
    [10] = {
        label = 'Tools Pack',
        rewards = {
            { type = 'item', name = 'lockpick', count = 1 }
        }
    },
    [11] = {
        label = 'Cash Pack',
        rewards = {
            { type = 'item', name = 'money', count = 7000 }
        }
    },
    [12] = {
        label = 'Snack Crate',
        rewards = {
            { type = 'item', name = 'bread', count = 4 },
            { type = 'item', name = 'water', count = 4 }
        }
    },
    [13] = {
        label = 'Bandage Bundle',
        rewards = {
            { type = 'item', name = 'bandage', count = 4 }
        }
    },
    [14] = {
        label = 'Ammo Bundle',
        rewards = {
            { type = 'item', name = 'ammo-9', count = 36 }
        }
    },
    [15] = {
        label = 'Mid Month Cash',
        rewards = {
            { type = 'item', name = 'money', count = 12000 }
        }
    },
    [16] = {
        label = 'Bread Pack',
        rewards = {
            { type = 'item', name = 'bread', count = 6 }
        }
    },
    [17] = {
        label = 'Water Pack',
        rewards = {
            { type = 'item', name = 'water', count = 6 }
        }
    },
    [18] = {
        label = 'Repair Pack',
        rewards = {
            { type = 'item', name = 'repairkit', count = 1 }
        }
    },
    [19] = {
        label = 'Utility Pack',
        rewards = {
            { type = 'item', name = 'lockpick', count = 2 }
        }
    },
    [20] = {
        label = 'Cash Reward',
        rewards = {
            { type = 'item', name = 'money', count = 9000 }
        }
    },
    [21] = {
        label = 'Food Combo',
        rewards = {
            { type = 'item', name = 'bread', count = 5 },
            { type = 'item', name = 'water', count = 5 }
        }
    },
    [22] = {
        label = 'Medical Combo',
        rewards = {
            { type = 'item', name = 'bandage', count = 5 }
        }
    },
    [23] = {
        label = 'Ammo Combo',
        rewards = {
            { type = 'item', name = 'ammo-9', count = 48 }
        }
    },
    [24] = {
        label = 'Radio Reward',
        rewards = {
            { type = 'item', name = 'radio', count = 1 }
        }
    },
    [25] = {
        label = 'Cash Boost',
        rewards = {
            { type = 'item', name = 'money', count = 15000 }
        }
    },
    [26] = {
        label = 'Bandage Bundle',
        rewards = {
            { type = 'item', name = 'bandage', count = 6 }
        }
    },
    [27] = {
        label = 'Repair Bundle',
        rewards = {
            { type = 'item', name = 'repairkit', count = 2 }
        }
    },
    [28] = {
        label = 'Survival Pack',
        rewards = {
            { type = 'item', name = 'bread', count = 6 },
            { type = 'item', name = 'water', count = 6 }
        }
    },
    [29] = {
        label = 'Heavy Ammo',
        rewards = {
            { type = 'item', name = 'ammo-9', count = 60 }
        }
    },
    [30] = {
        label = 'Final Reward',
        rewards = {
            { type = 'item', name = 'money', count = 25000 },
            { type = 'item', name = 'bandage', count = 5 }
        }
    }
}