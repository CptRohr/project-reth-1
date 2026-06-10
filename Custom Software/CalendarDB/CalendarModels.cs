using System.Text.Json.Serialization;

namespace CalendarDB;

public sealed class ActivityRow
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = "";

    [JsonPropertyName("name")]
    public string Name { get; set; } = "";

    [JsonPropertyName("description")]
    public string Description { get; set; } = "";

    [JsonPropertyName("available_days")]
    public List<string> AvailableDays { get; set; } = [];

    [JsonPropertyName("available_time_blocks")]
    public List<string> AvailableTimeBlocks { get; set; } = [];

    [JsonPropertyName("stat_effects")]
    public Dictionary<string, int> StatEffects { get; set; } = [];

    [JsonPropertyName("required_flags")]
    public List<string> RequiredFlags { get; set; } = [];

    [JsonPropertyName("set_flags_after_complete")]
    public List<string> SetFlagsAfterComplete { get; set; } = [];
}

public sealed class ActivityGridRow
{
    public string Id { get; set; } = "";
    public string Name { get; set; } = "";
    public string Description { get; set; } = "";
    public string AvailableDays { get; set; } = "";
    public string AvailableTimeBlocks { get; set; } = "";
    public string StatEffects { get; set; } = "";
    public string RequiredFlags { get; set; } = "";
    public string SetFlagsAfterComplete { get; set; } = "";
}

public sealed class WeeklyGridRow
{
    public string Day { get; set; } = "";
    public string TimeBlock { get; set; } = "";
    public string Type { get; set; } = "";
    public string ActivityId { get; set; } = "";
}

public sealed class SpecialEventRow
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = "";

    [JsonPropertyName("title")]
    public string Title { get; set; } = "";

    [JsonPropertyName("date")]
    public string Date { get; set; } = "";

    [JsonPropertyName("time_block")]
    public string TimeBlock { get; set; } = "";

    [JsonPropertyName("description")]
    public string Description { get; set; } = "";

    [JsonPropertyName("forced")]
    public bool Forced { get; set; }

    [JsonPropertyName("activity_id")]
    public string ActivityId { get; set; } = "";

    [JsonPropertyName("required_flags")]
    public List<string> RequiredFlags { get; set; } = [];

    [JsonPropertyName("set_flags_after_complete")]
    public List<string> SetFlagsAfterComplete { get; set; } = [];

    [JsonPropertyName("objective_text")]
    public string ObjectiveText { get; set; } = "";

    [JsonPropertyName("objective_required")]
    public bool ObjectiveRequired { get; set; }

    [JsonPropertyName("objective_complete_flag")]
    public string ObjectiveCompleteFlag { get; set; } = "";

    [JsonPropertyName("objective_blocked_message")]
    public string ObjectiveBlockedMessage { get; set; } = "";
}

public sealed class SpecialEventGridRow
{
    public string Id { get; set; } = "";
    public string Title { get; set; } = "";
    public string Date { get; set; } = "";
    public string TimeBlock { get; set; } = "";
    public string Description { get; set; } = "";
    public bool Forced { get; set; }
    public string ActivityId { get; set; } = "";
    public string RequiredFlags { get; set; } = "";
    public string SetFlagsAfterComplete { get; set; } = "";
    public string ObjectiveText { get; set; } = "";
    public bool ObjectiveRequired { get; set; }
    public string ObjectiveCompleteFlag { get; set; } = "";
    public string ObjectiveBlockedMessage { get; set; } = "";
}

public sealed class WeatherGridRow
{
    public string Date { get; set; } = "";
    public string Weather { get; set; } = "";
}

public sealed class NpcDatabase
{
    [JsonPropertyName("npcs")]
    public List<NpcRow> Npcs { get; set; } = [];

    [JsonPropertyName("appearance_rules")]
    public List<NpcAppearanceRuleRow> AppearanceRules { get; set; } = [];

    [JsonPropertyName("dialogue_routes")]
    public List<NpcDialogueRouteRow> DialogueRoutes { get; set; } = [];
}

public sealed class NpcRow
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = "";

    [JsonPropertyName("display_name")]
    public string DisplayName { get; set; } = "";

    [JsonPropertyName("default_timeline")]
    public string DefaultTimeline { get; set; } = "";

    [JsonPropertyName("visible_by_default")]
    public bool VisibleByDefault { get; set; }

    [JsonPropertyName("notes")]
    public string Notes { get; set; } = "";
}

public sealed class NpcGridRow
{
    public string Id { get; set; } = "";
    public string DisplayName { get; set; } = "";
    public string DefaultTimeline { get; set; } = "";
    public bool VisibleByDefault { get; set; }
    public string Notes { get; set; } = "";
}

public sealed class NpcAppearanceRuleRow
{
    [JsonPropertyName("npc_id")]
    public string NpcId { get; set; } = "";

    [JsonPropertyName("scene_path")]
    public string ScenePath { get; set; } = "";

    [JsonPropertyName("days")]
    public List<string> Days { get; set; } = [];

    [JsonPropertyName("dates")]
    public List<string> Dates { get; set; } = [];

    [JsonPropertyName("time_blocks")]
    public List<string> TimeBlocks { get; set; } = [];

    [JsonPropertyName("required_flags")]
    public List<string> RequiredFlags { get; set; } = [];

    [JsonPropertyName("blocked_flags")]
    public List<string> BlockedFlags { get; set; } = [];

    [JsonPropertyName("visible")]
    public bool Visible { get; set; } = true;

    [JsonPropertyName("interactable")]
    public bool Interactable { get; set; } = true;
}

public sealed class NpcAppearanceGridRow
{
    public string NpcId { get; set; } = "";
    public string ScenePath { get; set; } = "";
    public string Days { get; set; } = "";
    public string Dates { get; set; } = "";
    public string TimeBlocks { get; set; } = "";
    public string RequiredFlags { get; set; } = "";
    public string BlockedFlags { get; set; } = "";
    public bool Visible { get; set; } = true;
    public bool Interactable { get; set; } = true;
}

public sealed class NpcDialogueRouteRow
{
    [JsonPropertyName("npc_id")]
    public string NpcId { get; set; } = "";

    [JsonPropertyName("priority")]
    public int Priority { get; set; }

    [JsonPropertyName("timeline")]
    public string Timeline { get; set; } = "";

    [JsonPropertyName("days")]
    public List<string> Days { get; set; } = [];

    [JsonPropertyName("dates")]
    public List<string> Dates { get; set; } = [];

    [JsonPropertyName("time_blocks")]
    public List<string> TimeBlocks { get; set; } = [];

    [JsonPropertyName("required_flags")]
    public List<string> RequiredFlags { get; set; } = [];

    [JsonPropertyName("blocked_flags")]
    public List<string> BlockedFlags { get; set; } = [];

    [JsonPropertyName("set_flags_after_interaction")]
    public List<string> SetFlagsAfterInteraction { get; set; } = [];
}

public sealed class NpcDialogueGridRow
{
    public string NpcId { get; set; } = "";
    public int Priority { get; set; }
    public string Timeline { get; set; } = "";
    public string Days { get; set; } = "";
    public string Dates { get; set; } = "";
    public string TimeBlocks { get; set; } = "";
    public string RequiredFlags { get; set; } = "";
    public string BlockedFlags { get; set; } = "";
    public string SetFlagsAfterInteraction { get; set; } = "";
}
