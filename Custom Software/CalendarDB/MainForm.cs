using System.ComponentModel;
using System.Text.Json;

namespace CalendarDB;

public sealed class MainForm : Form
{
    private static readonly string[] Days =
    [
        "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"
    ];

    private static readonly string[] TimeBlocks =
    [
        "morning", "after_school", "evening", "night"
    ];

    private readonly JsonSerializerOptions jsonOptions = new()
    {
        WriteIndented = true,
        PropertyNamingPolicy = null
    };

    private readonly BindingList<ActivityGridRow> activities = [];
    private readonly BindingList<WeeklyGridRow> weeklyRows = [];
    private readonly BindingList<SpecialEventGridRow> specialEvents = [];

    private readonly DataGridView activitiesGrid = new();
    private readonly DataGridView weeklyGrid = new();
    private readonly DataGridView specialEventsGrid = new();
    private readonly TextBox validationBox = new();
    private readonly Label pathLabel = new();

    private readonly string projectRoot;
    private readonly string calendarDataPath;

    public MainForm()
    {
        projectRoot = FindProjectRoot();
        calendarDataPath = Path.Combine(projectRoot, "data", "calendar");

        Text = "CalendarDB";
        MinimumSize = new Size(1180, 720);
        StartPosition = FormStartPosition.CenterScreen;

        BuildUi();
        LoadData();
        ValidateAndShow();
    }

    private void BuildUi()
    {
        var root = new TableLayoutPanel
        {
            Dock = DockStyle.Fill,
            RowCount = 3,
            ColumnCount = 1
        };
        root.RowStyles.Add(new RowStyle(SizeType.Absolute, 44));
        root.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
        root.RowStyles.Add(new RowStyle(SizeType.Absolute, 32));

        var toolbar = new FlowLayoutPanel
        {
            Dock = DockStyle.Fill,
            FlowDirection = FlowDirection.LeftToRight,
            Padding = new Padding(8, 7, 8, 4)
        };

        var loadButton = new Button { Text = "Load JSON", AutoSize = true };
        loadButton.Click += (_, _) => LoadData();
        var saveButton = new Button { Text = "Validate + Save", AutoSize = true };
        saveButton.Click += (_, _) => SaveData();
        var addSampleButton = new Button { Text = "Add Sample Data", AutoSize = true };
        addSampleButton.Click += (_, _) => AddSampleData();

        toolbar.Controls.Add(loadButton);
        toolbar.Controls.Add(saveButton);
        toolbar.Controls.Add(addSampleButton);

        var tabs = new TabControl { Dock = DockStyle.Fill };
        tabs.TabPages.Add(CreateGridTab("Activities", activitiesGrid, activities));
        tabs.TabPages.Add(CreateWeeklyTab());
        tabs.TabPages.Add(CreateGridTab("Special Events", specialEventsGrid, specialEvents));
        tabs.TabPages.Add(CreateValidationTab());

        pathLabel.Dock = DockStyle.Fill;
        pathLabel.TextAlign = ContentAlignment.MiddleLeft;
        pathLabel.Padding = new Padding(10, 0, 0, 0);
        pathLabel.Text = $"Project: {projectRoot}";

        root.Controls.Add(toolbar, 0, 0);
        root.Controls.Add(tabs, 0, 1);
        root.Controls.Add(pathLabel, 0, 2);
        Controls.Add(root);

        ConfigureActivitiesGrid();
        ConfigureWeeklyGrid();
        ConfigureSpecialEventsGrid();
    }

    private static TabPage CreateGridTab<T>(string title, DataGridView grid, BindingList<T> source)
    {
        var tab = new TabPage(title);
        grid.Dock = DockStyle.Fill;
        grid.AutoGenerateColumns = true;
        grid.AllowUserToAddRows = true;
        grid.AllowUserToDeleteRows = true;
        grid.DataSource = source;
        tab.Controls.Add(grid);
        return tab;
    }

    private TabPage CreateWeeklyTab()
    {
        var tab = new TabPage("Weekly Schedule");
        weeklyGrid.Dock = DockStyle.Fill;
        weeklyGrid.AutoGenerateColumns = false;
        weeklyGrid.AllowUserToAddRows = false;
        weeklyGrid.AllowUserToDeleteRows = false;
        weeklyGrid.DataSource = weeklyRows;
        tab.Controls.Add(weeklyGrid);
        return tab;
    }

    private TabPage CreateValidationTab()
    {
        var tab = new TabPage("Validation");
        validationBox.Dock = DockStyle.Fill;
        validationBox.Multiline = true;
        validationBox.ReadOnly = true;
        validationBox.ScrollBars = ScrollBars.Both;
        validationBox.Font = new Font(FontFamily.GenericMonospace, 10f);

        var validateButton = new Button
        {
            Dock = DockStyle.Top,
            Height = 34,
            Text = "Refresh Validation"
        };
        validateButton.Click += (_, _) => ValidateAndShow();

        tab.Controls.Add(validationBox);
        tab.Controls.Add(validateButton);
        return tab;
    }

    private void ConfigureActivitiesGrid()
    {
        activitiesGrid.AutoGenerateColumns = false;
        activitiesGrid.Columns.Clear();
        AddTextColumn(activitiesGrid, nameof(ActivityGridRow.Id), "ID", 80);
        AddTextColumn(activitiesGrid, nameof(ActivityGridRow.Name), "Name", 120);
        AddTextColumn(activitiesGrid, nameof(ActivityGridRow.Description), "Description", 220);
        AddTextColumn(activitiesGrid, nameof(ActivityGridRow.AvailableDays), "Available Days", 180);
        AddTextColumn(activitiesGrid, nameof(ActivityGridRow.AvailableTimeBlocks), "Available Time Blocks", 170);
        AddTextColumn(activitiesGrid, nameof(ActivityGridRow.StatEffects), "Stat Effects (knowledge:2, energy:-1)", 190);
        AddTextColumn(activitiesGrid, nameof(ActivityGridRow.RequiredFlags), "Required Flags", 150);
        AddTextColumn(activitiesGrid, nameof(ActivityGridRow.SetFlagsAfterComplete), "Set Flags After Complete", 190);
        activitiesGrid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
    }

    private void ConfigureWeeklyGrid()
    {
        weeklyGrid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
        weeklyGrid.Columns.Add(new DataGridViewTextBoxColumn
        {
            DataPropertyName = nameof(WeeklyGridRow.Day),
            HeaderText = "Day",
            ReadOnly = true
        });
        weeklyGrid.Columns.Add(new DataGridViewTextBoxColumn
        {
            DataPropertyName = nameof(WeeklyGridRow.TimeBlock),
            HeaderText = "Time Block",
            ReadOnly = true
        });
        weeklyGrid.Columns.Add(new DataGridViewComboBoxColumn
        {
            DataPropertyName = nameof(WeeklyGridRow.Type),
            HeaderText = "Type",
            DataSource = new[] { "", "forced_activity" }
        });
        weeklyGrid.Columns.Add(new DataGridViewTextBoxColumn
        {
            DataPropertyName = nameof(WeeklyGridRow.ActivityId),
            HeaderText = "Activity ID"
        });
    }

    private void ConfigureSpecialEventsGrid()
    {
        specialEventsGrid.AutoGenerateColumns = false;
        specialEventsGrid.Columns.Clear();
        AddTextColumn(specialEventsGrid, nameof(SpecialEventGridRow.Id), "ID", 100);
        AddTextColumn(specialEventsGrid, nameof(SpecialEventGridRow.Title), "Title", 150);
        AddTextColumn(specialEventsGrid, nameof(SpecialEventGridRow.Date), "Date (YYYY-MM-DD)", 130);
        AddTextColumn(specialEventsGrid, nameof(SpecialEventGridRow.TimeBlock), "Time Block", 120);
        AddTextColumn(specialEventsGrid, nameof(SpecialEventGridRow.Description), "Description", 220);
        specialEventsGrid.Columns.Add(new DataGridViewCheckBoxColumn
        {
            DataPropertyName = nameof(SpecialEventGridRow.Forced),
            HeaderText = "Forced",
            FillWeight = 80
        });
        AddTextColumn(specialEventsGrid, nameof(SpecialEventGridRow.ActivityId), "Activity ID", 120);
        AddTextColumn(specialEventsGrid, nameof(SpecialEventGridRow.RequiredFlags), "Required Flags", 150);
        AddTextColumn(specialEventsGrid, nameof(SpecialEventGridRow.SetFlagsAfterComplete), "Set Flags After Complete", 190);
        specialEventsGrid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
    }

    private static void AddTextColumn(DataGridView grid, string propertyName, string headerText, float fillWeight)
    {
        grid.Columns.Add(new DataGridViewTextBoxColumn
        {
            DataPropertyName = propertyName,
            HeaderText = headerText,
            FillWeight = fillWeight
        });
    }

    private void LoadData()
    {
        Directory.CreateDirectory(calendarDataPath);
        activities.Clear();
        weeklyRows.Clear();
        specialEvents.Clear();

        foreach (var row in LoadActivities().Select(ToGridRow))
        {
            activities.Add(row);
        }

        foreach (var day in Days)
        {
            foreach (var timeBlock in TimeBlocks)
            {
                weeklyRows.Add(new WeeklyGridRow { Day = day, TimeBlock = timeBlock });
            }
        }

        LoadWeeklySchedule();

        foreach (var row in LoadSpecialEvents().Select(ToGridRow))
        {
            specialEvents.Add(row);
        }

        ValidateAndShow();
    }

    private List<ActivityRow> LoadActivities()
    {
        var path = Path.Combine(calendarDataPath, "activities.json");
        if (!File.Exists(path))
        {
            return [];
        }

        return JsonSerializer.Deserialize<List<ActivityRow>>(File.ReadAllText(path), jsonOptions) ?? [];
    }

    private List<SpecialEventRow> LoadSpecialEvents()
    {
        var path = Path.Combine(calendarDataPath, "special_events.json");
        if (!File.Exists(path))
        {
            return [];
        }

        return JsonSerializer.Deserialize<List<SpecialEventRow>>(File.ReadAllText(path), jsonOptions) ?? [];
    }

    private void LoadWeeklySchedule()
    {
        var path = Path.Combine(calendarDataPath, "weekly_schedule.json");
        if (!File.Exists(path))
        {
            return;
        }

        var data = JsonSerializer.Deserialize<Dictionary<string, Dictionary<string, Dictionary<string, string>>>>(
            File.ReadAllText(path),
            jsonOptions
        );

        if (data == null)
        {
            return;
        }

        foreach (var row in weeklyRows)
        {
            if (!data.TryGetValue(row.Day, out var slots))
            {
                continue;
            }

            if (!slots.TryGetValue(row.TimeBlock, out var slot))
            {
                continue;
            }

            row.Type = slot.GetValueOrDefault("type", "");
            row.ActivityId = slot.GetValueOrDefault("activity_id", "");
        }

        weeklyGrid.Refresh();
    }

    private void SaveData()
    {
        var errors = ValidateData();
        ShowValidation(errors);

        if (errors.Count > 0)
        {
            MessageBox.Show("Fix validation errors before saving.", "CalendarDB", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            return;
        }

        Directory.CreateDirectory(calendarDataPath);
        File.WriteAllText(
            Path.Combine(calendarDataPath, "activities.json"),
            JsonSerializer.Serialize(activities.Select(FromGridRow).ToList(), jsonOptions)
        );
        File.WriteAllText(
            Path.Combine(calendarDataPath, "weekly_schedule.json"),
            JsonSerializer.Serialize(BuildWeeklySchedule(), jsonOptions)
        );
        File.WriteAllText(
            Path.Combine(calendarDataPath, "special_events.json"),
            JsonSerializer.Serialize(specialEvents.Select(FromGridRow).ToList(), jsonOptions)
        );

        MessageBox.Show("Calendar JSON saved.", "CalendarDB", MessageBoxButtons.OK, MessageBoxIcon.Information);
    }

    private Dictionary<string, Dictionary<string, Dictionary<string, string>>> BuildWeeklySchedule()
    {
        var schedule = new Dictionary<string, Dictionary<string, Dictionary<string, string>>>();

        foreach (var day in Days)
        {
            schedule[day] = [];
        }

        foreach (var row in weeklyRows.Where(row => !string.IsNullOrWhiteSpace(row.Type) || !string.IsNullOrWhiteSpace(row.ActivityId)))
        {
            schedule[row.Day][row.TimeBlock] = new Dictionary<string, string>
            {
                ["type"] = Clean(row.Type),
                ["activity_id"] = Clean(row.ActivityId)
            };
        }

        return schedule.Where(pair => pair.Value.Count > 0).ToDictionary(pair => pair.Key, pair => pair.Value);
    }

    private void AddSampleData()
    {
        if (!activities.Any(row => row.Id == "study"))
        {
            activities.Add(new ActivityGridRow
            {
                Id = "study",
                Name = "Study",
                Description = "Study after school to increase knowledge.",
                AvailableDays = "monday, tuesday, wednesday, thursday, friday",
                AvailableTimeBlocks = "after_school, evening",
                StatEffects = "knowledge:2, energy:-1"
            });
        }

        if (!activities.Any(row => row.Id == "school"))
        {
            activities.Add(new ActivityGridRow
            {
                Id = "school",
                Name = "School",
                Description = "Attend normal morning classes.",
                AvailableDays = "monday, tuesday, wednesday, thursday, friday",
                AvailableTimeBlocks = "morning"
            });
        }

        if (!activities.Any(row => row.Id == "school_intro"))
        {
            activities.Add(new ActivityGridRow
            {
                Id = "school_intro",
                Name = "School Intro",
                Description = "The first morning at school.",
                AvailableDays = "monday",
                AvailableTimeBlocks = "morning",
                SetFlagsAfterComplete = "met_classmates"
            });
        }

        foreach (var row in weeklyRows.Where(row => Days.Take(5).Contains(row.Day) && row.TimeBlock == "morning"))
        {
            row.Type = "forced_activity";
            row.ActivityId = "school";
        }

        if (!specialEvents.Any(row => row.Id == "first_school_day"))
        {
            specialEvents.Add(new SpecialEventGridRow
            {
                Id = "first_school_day",
                Title = "First School Day",
                Date = "2026-04-13",
                TimeBlock = "morning",
                Description = "The first day of school.",
                Forced = true,
                ActivityId = "school_intro",
                SetFlagsAfterComplete = "met_classmates"
            });
        }

        weeklyGrid.Refresh();
        ValidateAndShow();
    }

    private List<string> ValidateData()
    {
        var errors = new List<string>();
        var activityIds = new HashSet<string>();

        foreach (var row in activities)
        {
            var id = Clean(row.Id);
            if (id.Length == 0)
            {
                errors.Add("Activity has a missing id.");
            }
            else if (!activityIds.Add(id))
            {
                errors.Add($"Duplicate activity id: {id}");
            }

            if (Clean(row.Name).Length == 0)
            {
                errors.Add($"Activity '{id}' is missing name.");
            }

            if (Clean(row.Description).Length == 0)
            {
                errors.Add($"Activity '{id}' is missing description.");
            }

            var availableDays = ParseList(row.AvailableDays);
            var availableTimeBlocks = ParseList(row.AvailableTimeBlocks);
            if (availableDays.Count == 0)
            {
                errors.Add($"Activity '{id}' is missing available days.");
            }

            if (availableTimeBlocks.Count == 0)
            {
                errors.Add($"Activity '{id}' is missing available time blocks.");
            }

            ValidateListValues(availableDays, Days, $"Activity '{id}' has invalid day", errors);
            ValidateListValues(availableTimeBlocks, TimeBlocks, $"Activity '{id}' has invalid time block", errors);

            try
            {
                ParseStatEffects(row.StatEffects);
            }
            catch (FormatException exception)
            {
                errors.Add($"Activity '{id}' stat effects error: {exception.Message}");
            }
        }

        foreach (var row in weeklyRows.Where(row => !string.IsNullOrWhiteSpace(row.Type) || !string.IsNullOrWhiteSpace(row.ActivityId)))
        {
            if (Clean(row.Type) != "forced_activity")
            {
                errors.Add($"Weekly {row.Day}/{row.TimeBlock} has invalid type '{row.Type}'.");
            }

            if (Clean(row.ActivityId).Length == 0)
            {
                errors.Add($"Weekly {row.Day}/{row.TimeBlock} is missing activity_id.");
            }
            else if (!activityIds.Contains(Clean(row.ActivityId)))
            {
                errors.Add($"Weekly {row.Day}/{row.TimeBlock} references missing activity_id '{row.ActivityId}'.");
            }
        }

        var specialIds = new HashSet<string>();
        foreach (var row in specialEvents)
        {
            var id = Clean(row.Id);
            if (id.Length == 0)
            {
                errors.Add("Special event has a missing id.");
            }
            else if (!specialIds.Add(id))
            {
                errors.Add($"Duplicate special event id: {id}");
            }

            if (Clean(row.Title).Length == 0)
            {
                errors.Add($"Special event '{id}' is missing title.");
            }

            if (Clean(row.Description).Length == 0)
            {
                errors.Add($"Special event '{id}' is missing description.");
            }

            if (!DateOnly.TryParseExact(Clean(row.Date), "yyyy-MM-dd", out _))
            {
                errors.Add($"Special event '{id}' has invalid date '{row.Date}'. Use YYYY-MM-DD.");
            }

            if (!TimeBlocks.Contains(Clean(row.TimeBlock)))
            {
                errors.Add($"Special event '{id}' has invalid time block '{row.TimeBlock}'.");
            }

            if (Clean(row.ActivityId).Length == 0)
            {
                errors.Add($"Special event '{id}' is missing activity_id.");
            }
            else if (!activityIds.Contains(Clean(row.ActivityId)))
            {
                errors.Add($"Special event '{id}' references missing activity_id '{row.ActivityId}'.");
            }
        }

        return errors;
    }

    private void ValidateAndShow()
    {
        ShowValidation(ValidateData());
    }

    private void ShowValidation(List<string> errors)
    {
        validationBox.Text = errors.Count == 0
            ? "No validation errors."
            : string.Join(Environment.NewLine, errors);
    }

    private static void ValidateListValues(IEnumerable<string> values, IReadOnlyCollection<string> validValues, string messagePrefix, List<string> errors)
    {
        foreach (var value in values.Where(value => !validValues.Contains(value)))
        {
            errors.Add($"{messagePrefix}: {value}");
        }
    }

    private static ActivityGridRow ToGridRow(ActivityRow row)
    {
        return new ActivityGridRow
        {
            Id = row.Id,
            Name = row.Name,
            Description = row.Description,
            AvailableDays = string.Join(", ", row.AvailableDays),
            AvailableTimeBlocks = string.Join(", ", row.AvailableTimeBlocks),
            StatEffects = string.Join(", ", row.StatEffects.Select(pair => $"{pair.Key}:{pair.Value}")),
            RequiredFlags = string.Join(", ", row.RequiredFlags),
            SetFlagsAfterComplete = string.Join(", ", row.SetFlagsAfterComplete)
        };
    }

    private static ActivityRow FromGridRow(ActivityGridRow row)
    {
        return new ActivityRow
        {
            Id = Clean(row.Id),
            Name = Clean(row.Name),
            Description = Clean(row.Description),
            AvailableDays = ParseList(row.AvailableDays),
            AvailableTimeBlocks = ParseList(row.AvailableTimeBlocks),
            StatEffects = ParseStatEffects(row.StatEffects),
            RequiredFlags = ParseList(row.RequiredFlags),
            SetFlagsAfterComplete = ParseList(row.SetFlagsAfterComplete)
        };
    }

    private static SpecialEventGridRow ToGridRow(SpecialEventRow row)
    {
        return new SpecialEventGridRow
        {
            Id = row.Id,
            Title = row.Title,
            Date = row.Date,
            TimeBlock = row.TimeBlock,
            Description = row.Description,
            Forced = row.Forced,
            ActivityId = row.ActivityId,
            RequiredFlags = string.Join(", ", row.RequiredFlags),
            SetFlagsAfterComplete = string.Join(", ", row.SetFlagsAfterComplete)
        };
    }

    private static SpecialEventRow FromGridRow(SpecialEventGridRow row)
    {
        return new SpecialEventRow
        {
            Id = Clean(row.Id),
            Title = Clean(row.Title),
            Date = Clean(row.Date),
            TimeBlock = Clean(row.TimeBlock),
            Description = Clean(row.Description),
            Forced = row.Forced,
            ActivityId = Clean(row.ActivityId),
            RequiredFlags = ParseList(row.RequiredFlags),
            SetFlagsAfterComplete = ParseList(row.SetFlagsAfterComplete)
        };
    }

    private static List<string> ParseList(string value)
    {
        return value
            .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Select(Clean)
            .Where(item => item.Length > 0)
            .ToList();
    }

    private static Dictionary<string, int> ParseStatEffects(string value)
    {
        var result = new Dictionary<string, int>();

        foreach (var item in ParseList(value))
        {
            var parts = item.Split(':', 2, StringSplitOptions.TrimEntries);
            if (parts.Length != 2 || parts[0].Length == 0 || !int.TryParse(parts[1], out var amount))
            {
                throw new FormatException($"Use stat:number pairs like knowledge:2. Bad item: {item}");
            }

            result[parts[0]] = amount;
        }

        return result;
    }

    private static string Clean(string? value)
    {
        return (value ?? "").Trim();
    }

    private static string FindProjectRoot()
    {
        var directory = new DirectoryInfo(AppContext.BaseDirectory);

        while (directory != null)
        {
            if (File.Exists(Path.Combine(directory.FullName, "project.godot")))
            {
                return directory.FullName;
            }

            directory = directory.Parent;
        }

        var current = new DirectoryInfo(Environment.CurrentDirectory);
        while (current != null)
        {
            if (File.Exists(Path.Combine(current.FullName, "project.godot")))
            {
                return current.FullName;
            }

            current = current.Parent;
        }

        return Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", ".."));
    }
}
