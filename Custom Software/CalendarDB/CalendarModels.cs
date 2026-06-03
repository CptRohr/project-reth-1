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
}
