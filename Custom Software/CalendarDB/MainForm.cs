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

    private static readonly string[] WeatherTypes =
    [
        "clear", "rain", "thunderstorm"
    ];

    private readonly JsonSerializerOptions jsonOptions = new()
    {
        WriteIndented = true,
        PropertyNamingPolicy = null
    };

    private readonly BindingList<ActivityGridRow> activities = [];
    private readonly BindingList<WeeklyGridRow> weeklyRows = [];
    private readonly BindingList<SpecialEventGridRow> specialEvents = [];
    private readonly BindingList<WeatherGridRow> weatherRows = [];
    private readonly BindingList<NpcGridRow> npcs = [];
    private readonly BindingList<NpcAppearanceGridRow> npcAppearanceRules = [];
    private readonly BindingList<NpcDialogueGridRow> npcDialogueRoutes = [];

    private readonly DataGridView activitiesGrid = new();
    private readonly DataGridView weeklyGrid = new();
    private readonly DataGridView specialEventsGrid = new();
    private readonly DataGridView weatherGrid = new();
    private readonly DataGridView npcsGrid = new();
    private readonly DataGridView npcAppearanceGrid = new();
    private readonly DataGridView npcDialogueGrid = new();
    private readonly TextBox validationBox = new();
    private readonly Label pathLabel = new();
    private TabControl? mainTabs;

    private readonly string projectRoot;
    private readonly string calendarDataPath;
    private readonly string npcDataPath;
    private bool isLoadingData;

    public MainForm()
    {
        projectRoot = FindProjectRoot();
        calendarDataPath = Path.Combine(projectRoot, "data", "calendar");
        npcDataPath = Path.Combine(projectRoot, "data", "npc");

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
        var duplicateButton = new Button { Text = "Duplicate Row", AutoSize = true };
        duplicateButton.Click += (_, _) => DuplicateSelectedRow();
        var deleteButton = new Button { Text = "Delete Row", AutoSize = true };
        deleteButton.Click += (_, _) => DeleteSelectedRow();
        var helpButton = new Button { Text = "How To Use", AutoSize = true };
        helpButton.Click += (_, _) => ShowHelp();

        toolbar.Controls.Add(loadButton);
        toolbar.Controls.Add(saveButton);
        toolbar.Controls.Add(addSampleButton);
        toolbar.Controls.Add(duplicateButton);
        toolbar.Controls.Add(deleteButton);
        toolbar.Controls.Add(helpButton);

        var tabs = new TabControl { Dock = DockStyle.Fill };
        mainTabs = tabs;
        tabs.Appearance = TabAppearance.Normal;
        tabs.HotTrack = true;
        tabs.TabPages.Add(CreateGridTab("Activities", activitiesGrid, activities, "Double-click Available Days or Available Time Blocks to pick from a checklist."));
        tabs.TabPages.Add(CreateWeeklyTab());
        tabs.TabPages.Add(CreateGridTab("Special Events", specialEventsGrid, specialEvents, "Use dropdowns for Time Block and Activity ID. Objective fields can drive the top-screen HUD."));
        tabs.TabPages.Add(CreateGridTab("Weather", weatherGrid, weatherRows, "Set one weather value for a whole story date. Missing dates are clear."));
        tabs.TabPages.Add(CreateGridTab("NPCs", npcsGrid, npcs, "Use the Default Timeline dropdown to pick an existing Dialogue/*.dtl timeline."));
        tabs.TabPages.Add(CreateGridTab("NPC Appearance", npcAppearanceGrid, npcAppearanceRules, "Use dropdowns for NPC ID and Scene Path. Double-click Days or Time Blocks for checklists."));
        tabs.TabPages.Add(CreateGridTab("NPC Dialogue Routes", npcDialogueGrid, npcDialogueRoutes, "Use dropdowns for NPC ID and Timeline. Lower Priority number wins."));
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
        ConfigureWeatherGrid();
        ConfigureNpcsGrid();
        ConfigureNpcAppearanceGrid();
        ConfigureNpcDialogueGrid();
        HookLiveValidation();
        ApplyEditorTheme(root, toolbar, tabs);
    }

    private static TabPage CreateGridTab<T>(string title, DataGridView grid, BindingList<T> source, string hint = "")
    {
        var tab = new TabPage(title);
        var layout = new TableLayoutPanel
        {
            Dock = DockStyle.Fill,
            RowCount = hint == "" ? 1 : 2,
            ColumnCount = 1
        };
        if (hint != "")
        {
            layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 30));
        }
        layout.RowStyles.Add(new RowStyle(SizeType.Percent, 100));

        if (hint != "")
        {
            var hintLabel = new Label
            {
                Dock = DockStyle.Fill,
                Text = hint,
                TextAlign = ContentAlignment.MiddleLeft,
                Padding = new Padding(10, 0, 10, 0),
                BackColor = Color.FromArgb(244, 247, 251),
                ForeColor = Color.FromArgb(64, 76, 92)
            };
            layout.Controls.Add(hintLabel, 0, 0);
        }

        grid.Dock = DockStyle.Fill;
        grid.AutoGenerateColumns = true;
        grid.AllowUserToAddRows = true;
        grid.AllowUserToDeleteRows = true;
        grid.DataSource = source;
        layout.Controls.Add(grid, 0, hint == "" ? 0 : 1);
        tab.Controls.Add(layout);
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
            Name = nameof(WeeklyGridRow.Type),
            DataPropertyName = nameof(WeeklyGridRow.Type),
            HeaderText = "Type",
            DataSource = new[] { "", "forced_activity" }
        });
        AddComboColumn(weeklyGrid, nameof(WeeklyGridRow.ActivityId), "Activity ID", 160, GetActivityIdOptions());
    }

    private void ConfigureSpecialEventsGrid()
    {
        specialEventsGrid.AutoGenerateColumns = false;
        specialEventsGrid.Columns.Clear();
        AddTextColumn(specialEventsGrid, nameof(SpecialEventGridRow.Id), "ID", 100);
        AddTextColumn(specialEventsGrid, nameof(SpecialEventGridRow.Title), "Title", 150);
        AddTextColumn(specialEventsGrid, nameof(SpecialEventGridRow.Date), "Date (YYYY-MM-DD)", 130);
        AddComboColumn(specialEventsGrid, nameof(SpecialEventGridRow.TimeBlock), "Time Block", 120, TimeBlocks);
        AddTextColumn(specialEventsGrid, nameof(SpecialEventGridRow.Description), "Description", 220);
        specialEventsGrid.Columns.Add(new DataGridViewCheckBoxColumn
        {
            DataPropertyName = nameof(SpecialEventGridRow.Forced),
            HeaderText = "Forced",
            FillWeight = 80
        });
        AddComboColumn(specialEventsGrid, nameof(SpecialEventGridRow.ActivityId), "Activity ID", 120, GetActivityIdOptions());
        AddTextColumn(specialEventsGrid, nameof(SpecialEventGridRow.RequiredFlags), "Required Flags", 150);
        AddTextColumn(specialEventsGrid, nameof(SpecialEventGridRow.SetFlagsAfterComplete), "Set Flags After Complete", 190);
        AddTextColumn(specialEventsGrid, nameof(SpecialEventGridRow.ObjectiveText), "Objective Text", 190);
        specialEventsGrid.Columns.Add(new DataGridViewCheckBoxColumn
        {
            DataPropertyName = nameof(SpecialEventGridRow.ObjectiveRequired),
            HeaderText = "Objective Required",
            FillWeight = 90
        });
        AddTextColumn(specialEventsGrid, nameof(SpecialEventGridRow.ObjectiveCompleteFlag), "Objective Complete Flag", 170);
        AddTextColumn(specialEventsGrid, nameof(SpecialEventGridRow.ObjectiveBlockedMessage), "Objective Blocked Message", 210);
        specialEventsGrid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
    }

    private void ConfigureWeatherGrid()
    {
        weatherGrid.AutoGenerateColumns = false;
        weatherGrid.Columns.Clear();
        AddTextColumn(weatherGrid, nameof(WeatherGridRow.Date), "Date (YYYY-MM-DD)", 150);
        AddComboColumn(weatherGrid, nameof(WeatherGridRow.Weather), "Weather", 160, WeatherTypes);
        weatherGrid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
    }

    private void ConfigureNpcsGrid()
    {
        npcsGrid.AutoGenerateColumns = false;
        npcsGrid.Columns.Clear();
        AddTextColumn(npcsGrid, nameof(NpcGridRow.Id), "ID", 120);
        AddTextColumn(npcsGrid, nameof(NpcGridRow.DisplayName), "Display Name", 160);
        AddComboColumn(npcsGrid, nameof(NpcGridRow.DefaultTimeline), "Default Timeline", 160, GetTimelineOptions());
        npcsGrid.Columns.Add(new DataGridViewCheckBoxColumn
        {
            DataPropertyName = nameof(NpcGridRow.VisibleByDefault),
            HeaderText = "Visible By Default",
            FillWeight = 90
        });
        AddTextColumn(npcsGrid, nameof(NpcGridRow.Notes), "Notes", 240);
        npcsGrid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
    }

    private void ConfigureNpcAppearanceGrid()
    {
        npcAppearanceGrid.AutoGenerateColumns = false;
        npcAppearanceGrid.Columns.Clear();
        AddComboColumn(npcAppearanceGrid, nameof(NpcAppearanceGridRow.NpcId), "NPC ID", 130, GetNpcIdOptions());
        AddComboColumn(npcAppearanceGrid, nameof(NpcAppearanceGridRow.ScenePath), "Scene Path", 220, GetScenePathOptions());
        AddTextColumn(npcAppearanceGrid, nameof(NpcAppearanceGridRow.Days), "Days", 150);
        AddTextColumn(npcAppearanceGrid, nameof(NpcAppearanceGridRow.Dates), "Dates", 150);
        AddTextColumn(npcAppearanceGrid, nameof(NpcAppearanceGridRow.TimeBlocks), "Time Blocks", 160);
        AddTextColumn(npcAppearanceGrid, nameof(NpcAppearanceGridRow.RequiredFlags), "Required Flags", 150);
        AddTextColumn(npcAppearanceGrid, nameof(NpcAppearanceGridRow.BlockedFlags), "Blocked Flags", 150);
        npcAppearanceGrid.Columns.Add(new DataGridViewCheckBoxColumn
        {
            DataPropertyName = nameof(NpcAppearanceGridRow.Visible),
            HeaderText = "Visible",
            FillWeight = 80
        });
        npcAppearanceGrid.Columns.Add(new DataGridViewCheckBoxColumn
        {
            DataPropertyName = nameof(NpcAppearanceGridRow.Interactable),
            HeaderText = "Interactable",
            FillWeight = 90
        });
        npcAppearanceGrid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
    }

    private void ConfigureNpcDialogueGrid()
    {
        npcDialogueGrid.AutoGenerateColumns = false;
        npcDialogueGrid.Columns.Clear();
        AddComboColumn(npcDialogueGrid, nameof(NpcDialogueGridRow.NpcId), "NPC ID", 130, GetNpcIdOptions());
        npcDialogueGrid.Columns.Add(new DataGridViewTextBoxColumn
        {
            DataPropertyName = nameof(NpcDialogueGridRow.Priority),
            HeaderText = "Priority",
            FillWeight = 80
        });
        AddComboColumn(npcDialogueGrid, nameof(NpcDialogueGridRow.Timeline), "Timeline", 160, GetTimelineOptions());
        AddTextColumn(npcDialogueGrid, nameof(NpcDialogueGridRow.Days), "Days", 150);
        AddTextColumn(npcDialogueGrid, nameof(NpcDialogueGridRow.Dates), "Dates", 150);
        AddTextColumn(npcDialogueGrid, nameof(NpcDialogueGridRow.TimeBlocks), "Time Blocks", 160);
        AddTextColumn(npcDialogueGrid, nameof(NpcDialogueGridRow.RequiredFlags), "Required Flags", 150);
        AddTextColumn(npcDialogueGrid, nameof(NpcDialogueGridRow.BlockedFlags), "Blocked Flags", 150);
        AddTextColumn(npcDialogueGrid, nameof(NpcDialogueGridRow.SetFlagsAfterInteraction), "Set Flags After Interaction", 190);
        npcDialogueGrid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
    }

    private void HookLiveValidation()
    {
        foreach (var grid in new[] { activitiesGrid, weeklyGrid, specialEventsGrid, weatherGrid, npcsGrid, npcAppearanceGrid, npcDialogueGrid })
        {
            grid.CellValueChanged += (_, _) => ValidateAndShow();
            grid.CellDoubleClick += OnGridCellDoubleClick;
            grid.CurrentCellDirtyStateChanged += (_, _) =>
            {
                if (grid.IsCurrentCellDirty)
                {
                    grid.CommitEdit(DataGridViewDataErrorContexts.Commit);
                }
            };
            grid.RowsAdded += (_, _) => ValidateAndShow();
            grid.RowsRemoved += (_, _) => ValidateAndShow();
            grid.DataError += (_, args) =>
            {
                args.ThrowException = false;
                ValidateAndShow();
            };
        }
    }

    private static void AddTextColumn(DataGridView grid, string propertyName, string headerText, float fillWeight)
    {
        grid.Columns.Add(new DataGridViewTextBoxColumn
        {
            Name = propertyName,
            DataPropertyName = propertyName,
            HeaderText = headerText,
            FillWeight = fillWeight
        });
    }

    private static void AddComboColumn(DataGridView grid, string propertyName, string headerText, float fillWeight, IEnumerable<string> values)
    {
        grid.Columns.Add(new DataGridViewComboBoxColumn
        {
            Name = propertyName,
            DataPropertyName = propertyName,
            HeaderText = headerText,
            FillWeight = fillWeight,
            FlatStyle = FlatStyle.Flat,
            DataSource = values.Distinct(StringComparer.OrdinalIgnoreCase).ToList()
        });
    }

    private void OnGridCellDoubleClick(object? sender, DataGridViewCellEventArgs args)
    {
        if (args.RowIndex < 0 || args.ColumnIndex < 0 || sender is not DataGridView grid)
        {
            return;
        }

        var propertyName = grid.Columns[args.ColumnIndex].DataPropertyName;
        var options = GetPickerOptions(propertyName);

        if (options.Length == 0)
        {
            return;
        }

        var cell = grid.Rows[args.RowIndex].Cells[args.ColumnIndex];
        var currentValue = Convert.ToString(cell.Value) ?? "";
        var pickedValue = ShowMultiSelectPicker(grid.Columns[args.ColumnIndex].HeaderText, options, currentValue);

        if (pickedValue == null)
        {
            return;
        }

        cell.Value = pickedValue;
        grid.CommitEdit(DataGridViewDataErrorContexts.Commit);
        ValidateAndShow();
    }

    private static string[] GetPickerOptions(string propertyName)
    {
        if (propertyName == nameof(ActivityGridRow.AvailableDays) || propertyName == nameof(NpcAppearanceGridRow.Days))
        {
            return Days;
        }

        if (propertyName == nameof(ActivityGridRow.AvailableTimeBlocks) || propertyName == nameof(NpcAppearanceGridRow.TimeBlocks))
        {
            return TimeBlocks;
        }

        return [];
    }

    private static string? ShowMultiSelectPicker(string title, IReadOnlyList<string> options, string currentValue)
    {
        using var form = new Form
        {
            Text = $"Pick {title}",
            StartPosition = FormStartPosition.CenterParent,
            Width = 360,
            Height = 420,
            MinimumSize = new Size(320, 360)
        };

        var layout = new TableLayoutPanel
        {
            Dock = DockStyle.Fill,
            RowCount = 3,
            ColumnCount = 1,
            Padding = new Padding(12)
        };
        layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 30));
        layout.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
        layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 42));

        var label = new Label
        {
            Dock = DockStyle.Fill,
            Text = "Choose one or more values. Leave all unchecked to mean any.",
            TextAlign = ContentAlignment.MiddleLeft
        };

        var list = new CheckedListBox
        {
            Dock = DockStyle.Fill,
            CheckOnClick = true
        };

        var currentValues = ParseList(currentValue).ToHashSet(StringComparer.OrdinalIgnoreCase);
        foreach (var option in options)
        {
            list.Items.Add(option, currentValues.Contains(option));
        }

        var buttons = new FlowLayoutPanel
        {
            Dock = DockStyle.Fill,
            FlowDirection = FlowDirection.RightToLeft
        };
        var okButton = new Button { Text = "OK", DialogResult = DialogResult.OK, Width = 84 };
        var cancelButton = new Button { Text = "Cancel", DialogResult = DialogResult.Cancel, Width = 84 };
        var clearButton = new Button { Text = "Any", Width = 84 };
        clearButton.Click += (_, _) =>
        {
            for (var index = 0; index < list.Items.Count; index++)
            {
                list.SetItemChecked(index, false);
            }
        };
        buttons.Controls.Add(okButton);
        buttons.Controls.Add(cancelButton);
        buttons.Controls.Add(clearButton);

        layout.Controls.Add(label, 0, 0);
        layout.Controls.Add(list, 0, 1);
        layout.Controls.Add(buttons, 0, 2);
        form.Controls.Add(layout);
        form.AcceptButton = okButton;
        form.CancelButton = cancelButton;

        if (form.ShowDialog() != DialogResult.OK)
        {
            return null;
        }

        return string.Join(", ", list.CheckedItems.Cast<string>());
    }

    private void ShowHelp()
    {
        MessageBox.Show(
            """
            CalendarDB quick guide

            Save writes:
            - data/calendar/activities.json
            - data/calendar/weekly_schedule.json
            - data/calendar/special_events.json
            - data/calendar/weather.json
            - data/npc/npcs.json

            Use dropdown cells for IDs, timelines, scenes, and single time blocks.
            Double-click day/time-block list cells to open a checklist picker.
            Select a row and press Delete Row to remove it.
            Select a row and press Duplicate Row to copy it.
            The Weekly Schedule grid is fixed; clear Type and Activity ID to remove a forced slot.
            The Weather tab sets one weather value for an entire story date. Missing dates are clear.

            Cell colors:
            - Red: invalid or broken reference; save will be blocked.
            - Yellow: empty wildcard list or optional objective without a completion flag.
            - White: valid.

            Special event objectives:
            - Objective Text appears in the top-screen HUD while the event is active.
            - Objective Required blocks optional/stat activities until Objective Complete Flag is true.
            - Objective Blocked Message is shown when a blocked activity is touched.

            NPC workflow:
            1. Create an NPC row.
            2. Add appearance rules for scene/time/day visibility.
            3. Add dialogue routes only for special overrides.
            4. Leave dialogue routes empty when a custom NPC script should handle its own progression.
            """,
            "CalendarDB Help",
            MessageBoxButtons.OK,
            MessageBoxIcon.Information
        );
    }

    private void DeleteSelectedRow()
    {
        var grid = GetActiveGrid();

        if (grid == null)
        {
            MessageBox.Show("Open an editable tab and select a row first.", "CalendarDB", MessageBoxButtons.OK, MessageBoxIcon.Information);
            return;
        }

        if (grid == weeklyGrid)
        {
            ClearSelectedWeeklyRows();
            return;
        }

        var rows = GetSelectedDataRows(grid).ToList();
        if (rows.Count == 0)
        {
            MessageBox.Show("Select one or more rows to delete.", "CalendarDB", MessageBoxButtons.OK, MessageBoxIcon.Information);
            return;
        }

        var result = MessageBox.Show(
            $"Delete {rows.Count} selected row(s)?",
            "CalendarDB",
            MessageBoxButtons.YesNo,
            MessageBoxIcon.Warning
        );

        if (result != DialogResult.Yes)
        {
            return;
        }

        foreach (var row in rows.OrderByDescending(row => row.Index))
        {
            grid.Rows.RemoveAt(row.Index);
        }

        ValidateAndShow();
    }

    private void DuplicateSelectedRow()
    {
        var grid = GetActiveGrid();

        if (grid == null || grid == weeklyGrid)
        {
            MessageBox.Show("Open an editable data tab and select one row to duplicate.", "CalendarDB", MessageBoxButtons.OK, MessageBoxIcon.Information);
            return;
        }

        var row = GetSelectedDataRows(grid).FirstOrDefault();
        if (row == null)
        {
            MessageBox.Show("Select a row to duplicate.", "CalendarDB", MessageBoxButtons.OK, MessageBoxIcon.Information);
            return;
        }

        if (grid == activitiesGrid)
        {
            var source = activities[row.Index];
            activities.Add(new ActivityGridRow
            {
                Id = $"{source.Id}_copy",
                Name = source.Name,
                Description = source.Description,
                AvailableDays = source.AvailableDays,
                AvailableTimeBlocks = source.AvailableTimeBlocks,
                StatEffects = source.StatEffects,
                RequiredFlags = source.RequiredFlags,
                SetFlagsAfterComplete = source.SetFlagsAfterComplete
            });
        }
        else if (grid == specialEventsGrid)
        {
            var source = specialEvents[row.Index];
            specialEvents.Add(new SpecialEventGridRow
            {
                Id = $"{source.Id}_copy",
                Title = source.Title,
                Date = source.Date,
                TimeBlock = source.TimeBlock,
                Description = source.Description,
                Forced = source.Forced,
                ActivityId = source.ActivityId,
                RequiredFlags = source.RequiredFlags,
                SetFlagsAfterComplete = source.SetFlagsAfterComplete,
                ObjectiveText = source.ObjectiveText,
                ObjectiveRequired = source.ObjectiveRequired,
                ObjectiveCompleteFlag = source.ObjectiveCompleteFlag,
                ObjectiveBlockedMessage = source.ObjectiveBlockedMessage
            });
        }
        else if (grid == weatherGrid)
        {
            var source = weatherRows[row.Index];
            weatherRows.Add(new WeatherGridRow
            {
                Date = source.Date,
                Weather = source.Weather
            });
        }
        else if (grid == npcsGrid)
        {
            var source = npcs[row.Index];
            npcs.Add(new NpcGridRow
            {
                Id = $"{source.Id}_copy",
                DisplayName = source.DisplayName,
                DefaultTimeline = source.DefaultTimeline,
                VisibleByDefault = source.VisibleByDefault,
                Notes = source.Notes
            });
        }
        else if (grid == npcAppearanceGrid)
        {
            var source = npcAppearanceRules[row.Index];
            npcAppearanceRules.Add(new NpcAppearanceGridRow
            {
                NpcId = source.NpcId,
                ScenePath = source.ScenePath,
                Days = source.Days,
                Dates = source.Dates,
                TimeBlocks = source.TimeBlocks,
                RequiredFlags = source.RequiredFlags,
                BlockedFlags = source.BlockedFlags,
                Visible = source.Visible,
                Interactable = source.Interactable
            });
        }
        else if (grid == npcDialogueGrid)
        {
            var source = npcDialogueRoutes[row.Index];
            npcDialogueRoutes.Add(new NpcDialogueGridRow
            {
                NpcId = source.NpcId,
                Priority = source.Priority,
                Timeline = source.Timeline,
                Days = source.Days,
                Dates = source.Dates,
                TimeBlocks = source.TimeBlocks,
                RequiredFlags = source.RequiredFlags,
                BlockedFlags = source.BlockedFlags,
                SetFlagsAfterInteraction = source.SetFlagsAfterInteraction
            });
        }

        ValidateAndShow();
    }

    private void ClearSelectedWeeklyRows()
    {
        var rows = GetSelectedDataRows(weeklyGrid).ToList();
        if (rows.Count == 0)
        {
            MessageBox.Show("Select weekly schedule rows to clear.", "CalendarDB", MessageBoxButtons.OK, MessageBoxIcon.Information);
            return;
        }

        foreach (var row in rows)
        {
            weeklyRows[row.Index].Type = "";
            weeklyRows[row.Index].ActivityId = "";
        }

        weeklyGrid.Refresh();
        ValidateAndShow();
    }

    private DataGridView? GetActiveGrid()
    {
        if (mainTabs == null)
        {
            return null;
        }

        return mainTabs.SelectedTab?
            .Controls
            .Cast<Control>()
            .SelectMany(FlattenControls)
            .OfType<DataGridView>()
            .FirstOrDefault();
    }

    private static IEnumerable<DataGridViewRow> GetSelectedDataRows(DataGridView grid)
    {
        return grid.SelectedRows
            .Cast<DataGridViewRow>()
            .Where(row => !row.IsNewRow)
            .DefaultIfEmpty(grid.CurrentRow)
            .Where(row => row != null && !row.IsNewRow)
            .Cast<DataGridViewRow>()
            .Distinct();
    }

    private static void ApplyEditorTheme(Control root, Control toolbar, TabControl tabs)
    {
        var background = Color.FromArgb(236, 240, 245);
        var surface = Color.FromArgb(250, 252, 255);
        var text = Color.FromArgb(32, 43, 55);

        root.BackColor = background;
        toolbar.BackColor = Color.FromArgb(226, 232, 240);
        tabs.BackColor = background;

        foreach (var grid in root.Controls
            .Cast<Control>()
            .SelectMany(FlattenControls)
            .OfType<DataGridView>())
        {
            grid.BackgroundColor = surface;
            grid.BorderStyle = BorderStyle.None;
            grid.GridColor = Color.FromArgb(218, 226, 235);
            grid.RowHeadersWidth = 28;
            grid.EnableHeadersVisualStyles = false;
            grid.ColumnHeadersDefaultCellStyle.BackColor = Color.FromArgb(52, 71, 92);
            grid.ColumnHeadersDefaultCellStyle.ForeColor = Color.White;
            grid.ColumnHeadersDefaultCellStyle.SelectionBackColor = Color.FromArgb(52, 71, 92);
            grid.ColumnHeadersDefaultCellStyle.Font = new Font(grid.Font, FontStyle.Bold);
            grid.DefaultCellStyle.BackColor = surface;
            grid.DefaultCellStyle.ForeColor = text;
            grid.DefaultCellStyle.SelectionBackColor = Color.FromArgb(197, 220, 245);
            grid.DefaultCellStyle.SelectionForeColor = text;
            grid.AlternatingRowsDefaultCellStyle.BackColor = Color.FromArgb(244, 247, 251);
            grid.AutoSizeRowsMode = DataGridViewAutoSizeRowsMode.DisplayedCellsExceptHeaders;
        }
    }

    private static IEnumerable<Control> FlattenControls(Control control)
    {
        foreach (Control child in control.Controls)
        {
            yield return child;

            foreach (var grandChild in FlattenControls(child))
            {
                yield return grandChild;
            }
        }
    }

    private void LoadData()
    {
        isLoadingData = true;
        Directory.CreateDirectory(calendarDataPath);
        Directory.CreateDirectory(npcDataPath);
        activities.Clear();
        weeklyRows.Clear();
        specialEvents.Clear();
        weatherRows.Clear();
        npcs.Clear();
        npcAppearanceRules.Clear();
        npcDialogueRoutes.Clear();

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

        foreach (var row in LoadWeatherRows())
        {
            weatherRows.Add(row);
        }

        var npcDatabase = LoadNpcDatabase();
        foreach (var row in npcDatabase.Npcs.Select(ToGridRow))
        {
            npcs.Add(row);
        }

        foreach (var row in npcDatabase.AppearanceRules.Select(ToGridRow))
        {
            npcAppearanceRules.Add(row);
        }

        foreach (var row in npcDatabase.DialogueRoutes.Select(ToGridRow))
        {
            npcDialogueRoutes.Add(row);
        }

        isLoadingData = false;
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

    private List<WeatherGridRow> LoadWeatherRows()
    {
        var path = Path.Combine(calendarDataPath, "weather.json");
        if (!File.Exists(path))
        {
            return [];
        }

        var data = JsonSerializer.Deserialize<Dictionary<string, string>>(
            File.ReadAllText(path),
            jsonOptions
        );

        if (data == null)
        {
            return [];
        }

        return data
            .Select(pair => new WeatherGridRow { Date = pair.Key, Weather = pair.Value })
            .OrderBy(row => row.Date)
            .ToList();
    }

    private NpcDatabase LoadNpcDatabase()
    {
        var path = Path.Combine(npcDataPath, "npcs.json");
        if (!File.Exists(path))
        {
            return new NpcDatabase();
        }

        return JsonSerializer.Deserialize<NpcDatabase>(File.ReadAllText(path), jsonOptions) ?? new NpcDatabase();
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
        File.WriteAllText(
            Path.Combine(calendarDataPath, "weather.json"),
            JsonSerializer.Serialize(BuildWeatherSchedule(), jsonOptions)
        );
        Directory.CreateDirectory(npcDataPath);
        File.WriteAllText(
            Path.Combine(npcDataPath, "npcs.json"),
            JsonSerializer.Serialize(BuildNpcDatabase(), jsonOptions)
        );

        MessageBox.Show("Calendar JSON saved.", "CalendarDB", MessageBoxButtons.OK, MessageBoxIcon.Information);
    }

    private NpcDatabase BuildNpcDatabase()
    {
        return new NpcDatabase
        {
            Npcs = npcs.Select(FromGridRow).ToList(),
            AppearanceRules = npcAppearanceRules.Select(FromGridRow).ToList(),
            DialogueRoutes = npcDialogueRoutes.Select(FromGridRow).OrderBy(row => row.Priority).ToList()
        };
    }

    private Dictionary<string, string> BuildWeatherSchedule()
    {
        return weatherRows
            .Where(row => Clean(row.Date).Length > 0 && Clean(row.Weather).Length > 0)
            .OrderBy(row => Clean(row.Date))
            .ToDictionary(row => Clean(row.Date), row => Clean(row.Weather));
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
                SetFlagsAfterComplete = "met_classmates",
                ObjectiveText = "Go to school for your first day.",
                ObjectiveRequired = true,
                ObjectiveCompleteFlag = "met_classmates",
                ObjectiveBlockedMessage = "Go to school first."
            });
        }

        if (!weatherRows.Any(row => row.Date == "2026-04-07"))
        {
            weatherRows.Add(new WeatherGridRow
            {
                Date = "2026-04-07",
                Weather = "rain"
            });
        }

        if (!npcs.Any(row => row.Id == "abang_brewok"))
        {
            npcs.Add(new NpcGridRow
            {
                Id = "abang_brewok",
                DisplayName = "Abang Brewok",
                DefaultTimeline = "AbangBrewok",
                VisibleByDefault = false,
                Notes = "Sample NPC controlled by NPCData."
            });
        }

        if (!npcAppearanceRules.Any(row => row.NpcId == "abang_brewok"))
        {
            npcAppearanceRules.Add(new NpcAppearanceGridRow
            {
                NpcId = "abang_brewok",
                ScenePath = "res://Areas/street.tscn",
                Days = "monday, tuesday, wednesday, thursday, friday",
                TimeBlocks = "after_school, evening",
                Visible = true,
                Interactable = true
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

            if (row.ObjectiveRequired)
            {
                if (Clean(row.ObjectiveText).Length == 0)
                {
                    errors.Add($"Special event '{id}' has a required objective but objective_text is empty.");
                }

                if (Clean(row.ObjectiveCompleteFlag).Length == 0)
                {
                    errors.Add($"Special event '{id}' has a required objective but objective_complete_flag is empty.");
                }
            }
        }

        var weatherDates = new HashSet<string>();
        foreach (var row in weatherRows)
        {
            var date = Clean(row.Date);
            if (date.Length == 0)
            {
                errors.Add("Weather row has a missing date.");
            }
            else if (!DateOnly.TryParseExact(date, "yyyy-MM-dd", out _))
            {
                errors.Add($"Weather row has invalid date '{row.Date}'. Use YYYY-MM-DD.");
            }
            else if (!weatherDates.Add(date))
            {
                errors.Add($"Duplicate weather date: {date}");
            }

            if (!WeatherTypes.Contains(Clean(row.Weather)))
            {
                errors.Add($"Weather row for '{date}' has invalid weather '{row.Weather}'.");
            }
        }

        var timelineNames = GetTimelineNames();
        var npcIds = new HashSet<string>();
        foreach (var row in npcs)
        {
            var id = Clean(row.Id);
            if (id.Length == 0)
            {
                errors.Add("NPC has a missing id.");
            }
            else if (!npcIds.Add(id))
            {
                errors.Add($"Duplicate NPC id: {id}");
            }

            if (Clean(row.DisplayName).Length == 0)
            {
                errors.Add($"NPC '{id}' is missing display_name.");
            }

            var defaultTimeline = Clean(row.DefaultTimeline);
            if (defaultTimeline.Length == 0)
            {
                errors.Add($"NPC '{id}' is missing default_timeline.");
            }
            else if (!timelineNames.Contains(defaultTimeline))
            {
                errors.Add($"NPC '{id}' default_timeline does not exist: {defaultTimeline}");
            }
        }

        foreach (var row in npcAppearanceRules)
        {
            var npcId = Clean(row.NpcId);
            if (npcId.Length == 0)
            {
                errors.Add("NPC appearance rule has a missing npc_id.");
            }
            else if (!npcIds.Contains(npcId))
            {
                errors.Add($"NPC appearance rule references missing npc_id '{npcId}'.");
            }

            var scenePath = Clean(row.ScenePath);
            if (scenePath.Length == 0)
            {
                errors.Add($"NPC appearance rule for '{npcId}' is missing scene_path.");
            }
            else if (!ResourcePathExists(scenePath))
            {
                errors.Add($"NPC appearance rule for '{npcId}' has missing scene_path '{scenePath}'.");
            }

            ValidateListValues(ParseList(row.Days), Days, $"NPC appearance rule for '{npcId}' has invalid day", errors);
            ValidateListValues(ParseList(row.TimeBlocks), TimeBlocks, $"NPC appearance rule for '{npcId}' has invalid time block", errors);
            ValidateDates(ParseList(row.Dates), $"NPC appearance rule for '{npcId}'", errors);
        }

        foreach (var row in npcDialogueRoutes)
        {
            var npcId = Clean(row.NpcId);
            if (npcId.Length == 0)
            {
                errors.Add("NPC dialogue route has a missing npc_id.");
            }
            else if (!npcIds.Contains(npcId))
            {
                errors.Add($"NPC dialogue route references missing npc_id '{npcId}'.");
            }

            var timeline = Clean(row.Timeline);
            if (timeline.Length == 0)
            {
                errors.Add($"NPC dialogue route for '{npcId}' is missing timeline.");
            }
            else if (!timelineNames.Contains(timeline))
            {
                errors.Add($"NPC dialogue route for '{npcId}' has missing timeline '{timeline}'.");
            }

            ValidateListValues(ParseList(row.Days), Days, $"NPC dialogue route for '{npcId}' has invalid day", errors);
            ValidateListValues(ParseList(row.TimeBlocks), TimeBlocks, $"NPC dialogue route for '{npcId}' has invalid time block", errors);
            ValidateDates(ParseList(row.Dates), $"NPC dialogue route for '{npcId}'", errors);
        }

        return errors;
    }

    private void ValidateAndShow()
    {
        if (isLoadingData)
        {
            return;
        }

        RefreshDropdownOptions();
        ShowValidation(ValidateData());
    }

    private void ShowValidation(List<string> errors)
    {
        validationBox.Text = errors.Count == 0
            ? "No validation errors."
            : string.Join(Environment.NewLine, errors);
        ApplyLiveValidationColors();
    }

    private static void ValidateListValues(IEnumerable<string> values, IReadOnlyCollection<string> validValues, string messagePrefix, List<string> errors)
    {
        foreach (var value in values.Where(value => !validValues.Contains(value)))
        {
            errors.Add($"{messagePrefix}: {value}");
        }
    }

    private static void ValidateDates(IEnumerable<string> dates, string messagePrefix, List<string> errors)
    {
        foreach (var date in dates)
        {
            if (!DateOnly.TryParseExact(date, "yyyy-MM-dd", out _))
            {
                errors.Add($"{messagePrefix} has invalid date '{date}'. Use YYYY-MM-DD.");
            }
        }
    }

    private void ApplyLiveValidationColors()
    {
        ResetGridColors(specialEventsGrid);
        ResetGridColors(weatherGrid);
        ResetGridColors(npcsGrid);
        ResetGridColors(npcAppearanceGrid);
        ResetGridColors(npcDialogueGrid);

        var activityIdSet = activities
            .Select(row => Clean(row.Id))
            .Where(id => id.Length > 0)
            .ToHashSet();
        var duplicateSpecialIds = specialEvents
            .Select(row => Clean(row.Id))
            .Where(id => id.Length > 0)
            .GroupBy(id => id)
            .Where(group => group.Count() > 1)
            .Select(group => group.Key)
            .ToHashSet();

        for (var index = 0; index < specialEvents.Count; index++)
        {
            var row = specialEvents[index];
            var id = Clean(row.Id);
            var activityId = Clean(row.ActivityId);

            if (id.Length == 0 || duplicateSpecialIds.Contains(id))
            {
                PaintCell(specialEventsGrid, index, nameof(SpecialEventGridRow.Id), Color.MistyRose);
            }

            if (Clean(row.Title).Length == 0)
            {
                PaintCell(specialEventsGrid, index, nameof(SpecialEventGridRow.Title), Color.MistyRose);
            }

            if (Clean(row.Description).Length == 0)
            {
                PaintCell(specialEventsGrid, index, nameof(SpecialEventGridRow.Description), Color.MistyRose);
            }

            if (!DateOnly.TryParseExact(Clean(row.Date), "yyyy-MM-dd", out _))
            {
                PaintCell(specialEventsGrid, index, nameof(SpecialEventGridRow.Date), Color.MistyRose);
            }

            if (!TimeBlocks.Contains(Clean(row.TimeBlock)))
            {
                PaintCell(specialEventsGrid, index, nameof(SpecialEventGridRow.TimeBlock), Color.MistyRose);
            }

            if (activityId.Length == 0 || !activityIdSet.Contains(activityId))
            {
                PaintCell(specialEventsGrid, index, nameof(SpecialEventGridRow.ActivityId), Color.MistyRose);
            }

            if (row.ObjectiveRequired)
            {
                if (Clean(row.ObjectiveText).Length == 0)
                {
                    PaintCell(specialEventsGrid, index, nameof(SpecialEventGridRow.ObjectiveText), Color.MistyRose);
                }

                if (Clean(row.ObjectiveCompleteFlag).Length == 0)
                {
                    PaintCell(specialEventsGrid, index, nameof(SpecialEventGridRow.ObjectiveCompleteFlag), Color.MistyRose);
                }
            }
            else if (Clean(row.ObjectiveText).Length > 0 && Clean(row.ObjectiveCompleteFlag).Length == 0)
            {
                PaintCell(specialEventsGrid, index, nameof(SpecialEventGridRow.ObjectiveCompleteFlag), Color.LemonChiffon);
            }
        }

        var duplicateWeatherDates = weatherRows
            .Select(row => Clean(row.Date))
            .Where(date => date.Length > 0)
            .GroupBy(date => date)
            .Where(group => group.Count() > 1)
            .Select(group => group.Key)
            .ToHashSet();

        for (var index = 0; index < weatherRows.Count; index++)
        {
            var row = weatherRows[index];
            var date = Clean(row.Date);

            if (date.Length == 0 || duplicateWeatherDates.Contains(date) || !DateOnly.TryParseExact(date, "yyyy-MM-dd", out _))
            {
                PaintCell(weatherGrid, index, nameof(WeatherGridRow.Date), Color.MistyRose);
            }

            if (!WeatherTypes.Contains(Clean(row.Weather)))
            {
                PaintCell(weatherGrid, index, nameof(WeatherGridRow.Weather), Color.MistyRose);
            }
        }

        var npcIds = npcs.Select(row => Clean(row.Id)).Where(id => id.Length > 0).ToList();
        var duplicateNpcIds = npcIds.GroupBy(id => id).Where(group => group.Count() > 1).Select(group => group.Key).ToHashSet();
        var npcIdSet = npcIds.ToHashSet();
        var timelineNames = GetTimelineNames();

        for (var index = 0; index < npcs.Count; index++)
        {
            var row = npcs[index];
            var id = Clean(row.Id);
            var timeline = Clean(row.DefaultTimeline);

            if (id.Length == 0 || duplicateNpcIds.Contains(id))
            {
                PaintCell(npcsGrid, index, nameof(NpcGridRow.Id), Color.MistyRose);
            }

            if (Clean(row.DisplayName).Length == 0)
            {
                PaintCell(npcsGrid, index, nameof(NpcGridRow.DisplayName), Color.MistyRose);
            }

            if (timeline.Length == 0 || !timelineNames.Contains(timeline))
            {
                PaintCell(npcsGrid, index, nameof(NpcGridRow.DefaultTimeline), Color.MistyRose);
            }
        }

        for (var index = 0; index < npcAppearanceRules.Count; index++)
        {
            var row = npcAppearanceRules[index];
            var npcId = Clean(row.NpcId);
            var scenePath = Clean(row.ScenePath);

            if (npcId.Length == 0 || !npcIdSet.Contains(npcId))
            {
                PaintCell(npcAppearanceGrid, index, nameof(NpcAppearanceGridRow.NpcId), Color.MistyRose);
            }

            if (scenePath.Length == 0 || !ResourcePathExists(scenePath))
            {
                PaintCell(npcAppearanceGrid, index, nameof(NpcAppearanceGridRow.ScenePath), Color.MistyRose);
            }

            PaintListCell(npcAppearanceGrid, index, nameof(NpcAppearanceGridRow.Days), row.Days, Days, true);
            PaintDateListCell(npcAppearanceGrid, index, nameof(NpcAppearanceGridRow.Dates), row.Dates, true);
            PaintListCell(npcAppearanceGrid, index, nameof(NpcAppearanceGridRow.TimeBlocks), row.TimeBlocks, TimeBlocks, true);
        }

        for (var index = 0; index < npcDialogueRoutes.Count; index++)
        {
            var row = npcDialogueRoutes[index];
            var npcId = Clean(row.NpcId);
            var timeline = Clean(row.Timeline);

            if (npcId.Length == 0 || !npcIdSet.Contains(npcId))
            {
                PaintCell(npcDialogueGrid, index, nameof(NpcDialogueGridRow.NpcId), Color.MistyRose);
            }

            if (timeline.Length == 0 || !timelineNames.Contains(timeline))
            {
                PaintCell(npcDialogueGrid, index, nameof(NpcDialogueGridRow.Timeline), Color.MistyRose);
            }

            PaintListCell(npcDialogueGrid, index, nameof(NpcDialogueGridRow.Days), row.Days, Days, true);
            PaintDateListCell(npcDialogueGrid, index, nameof(NpcDialogueGridRow.Dates), row.Dates, true);
            PaintListCell(npcDialogueGrid, index, nameof(NpcDialogueGridRow.TimeBlocks), row.TimeBlocks, TimeBlocks, true);
        }
    }

    private static void ResetGridColors(DataGridView grid)
    {
        foreach (DataGridViewRow row in grid.Rows)
        {
            if (row.IsNewRow)
            {
                continue;
            }

            foreach (DataGridViewCell cell in row.Cells)
            {
                cell.Style.BackColor = Color.White;
                cell.Style.SelectionBackColor = SystemColors.Highlight;
            }
        }
    }

    private static void PaintListCell(DataGridView grid, int rowIndex, string propertyName, string? value, IReadOnlyCollection<string> validValues, bool yellowWhenEmpty)
    {
        var values = ParseList(value);
        if (values.Count == 0 && yellowWhenEmpty)
        {
            PaintCell(grid, rowIndex, propertyName, Color.LemonChiffon);
            return;
        }

        if (values.Any(item => !validValues.Contains(item)))
        {
            PaintCell(grid, rowIndex, propertyName, Color.MistyRose);
        }
    }

    private static void PaintDateListCell(DataGridView grid, int rowIndex, string propertyName, string? value, bool yellowWhenEmpty)
    {
        var dates = ParseList(value);
        if (dates.Count == 0 && yellowWhenEmpty)
        {
            PaintCell(grid, rowIndex, propertyName, Color.LemonChiffon);
            return;
        }

        if (dates.Any(date => !DateOnly.TryParseExact(date, "yyyy-MM-dd", out _)))
        {
            PaintCell(grid, rowIndex, propertyName, Color.MistyRose);
        }
    }

    private static void PaintCell(DataGridView grid, int rowIndex, string propertyName, Color color)
    {
        if (rowIndex < 0 || rowIndex >= grid.Rows.Count)
        {
            return;
        }

        var column = grid.Columns
            .Cast<DataGridViewColumn>()
            .FirstOrDefault(item => item.DataPropertyName == propertyName || item.Name == propertyName);

        if (column == null)
        {
            return;
        }

        var cell = grid.Rows[rowIndex].Cells[column.Index];
        cell.Style.BackColor = color;
        cell.Style.SelectionBackColor = color == Color.MistyRose ? Color.IndianRed : Color.Goldenrod;
    }

    private HashSet<string> GetTimelineNames()
    {
        var dialoguePath = Path.Combine(projectRoot, "Dialogue");
        if (!Directory.Exists(dialoguePath))
        {
            return [];
        }

        return Directory
            .EnumerateFiles(dialoguePath, "*.dtl", SearchOption.TopDirectoryOnly)
            .Select(path => Path.GetFileNameWithoutExtension(path))
            .ToHashSet(StringComparer.OrdinalIgnoreCase);
    }

    private bool ResourcePathExists(string resourcePath)
    {
        var cleanPath = Clean(resourcePath);
        if (!cleanPath.StartsWith("res://", StringComparison.Ordinal))
        {
            return false;
        }

        var relativePath = cleanPath["res://".Length..].Replace('/', Path.DirectorySeparatorChar);
        return File.Exists(Path.Combine(projectRoot, relativePath));
    }

    private void RefreshDropdownOptions()
    {
        UpdateComboColumn(weeklyGrid, nameof(WeeklyGridRow.ActivityId), GetActivityIdOptions(weeklyRows.Select(row => row.ActivityId)));
        UpdateComboColumn(specialEventsGrid, nameof(SpecialEventGridRow.TimeBlock), TimeBlocks);
        UpdateComboColumn(specialEventsGrid, nameof(SpecialEventGridRow.ActivityId), GetActivityIdOptions(specialEvents.Select(row => row.ActivityId)));
        UpdateComboColumn(weatherGrid, nameof(WeatherGridRow.Weather), WeatherTypes.Concat(weatherRows.Select(row => row.Weather)));
        UpdateComboColumn(npcsGrid, nameof(NpcGridRow.DefaultTimeline), GetTimelineOptions(npcs.Select(row => row.DefaultTimeline)));
        UpdateComboColumn(npcAppearanceGrid, nameof(NpcAppearanceGridRow.NpcId), GetNpcIdOptions(npcAppearanceRules.Select(row => row.NpcId)));
        UpdateComboColumn(npcAppearanceGrid, nameof(NpcAppearanceGridRow.ScenePath), GetScenePathOptions(npcAppearanceRules.Select(row => row.ScenePath)));
        UpdateComboColumn(npcDialogueGrid, nameof(NpcDialogueGridRow.NpcId), GetNpcIdOptions(npcDialogueRoutes.Select(row => row.NpcId)));
        UpdateComboColumn(npcDialogueGrid, nameof(NpcDialogueGridRow.Timeline), GetTimelineOptions(npcDialogueRoutes.Select(row => row.Timeline)));
    }

    private static void UpdateComboColumn(DataGridView grid, string propertyName, IEnumerable<string> values)
    {
        var column = grid.Columns
            .Cast<DataGridViewColumn>()
            .FirstOrDefault(item => item.DataPropertyName == propertyName || item.Name == propertyName);

        if (column is not DataGridViewComboBoxColumn comboColumn)
        {
            return;
        }

        comboColumn.DataSource = values
            .Select(Clean)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .OrderBy(value => value)
            .ToList();
    }

    private IEnumerable<string> GetActivityIdOptions(IEnumerable<string>? includeValues = null)
    {
        return MergeOptions(activities.Select(row => row.Id), includeValues);
    }

    private IEnumerable<string> GetNpcIdOptions(IEnumerable<string>? includeValues = null)
    {
        return MergeOptions(npcs.Select(row => row.Id), includeValues);
    }

    private IEnumerable<string> GetTimelineOptions(IEnumerable<string>? includeValues = null)
    {
        return MergeOptions(GetTimelineNames(), includeValues);
    }

    private IEnumerable<string> GetScenePathOptions(IEnumerable<string>? includeValues = null)
    {
        var scenes = Directory
            .EnumerateFiles(projectRoot, "*.tscn", SearchOption.AllDirectories)
            .Where(path => !path.Contains($"{Path.DirectorySeparatorChar}.godot{Path.DirectorySeparatorChar}", StringComparison.OrdinalIgnoreCase))
            .Where(path => !path.Contains($"{Path.DirectorySeparatorChar}android{Path.DirectorySeparatorChar}", StringComparison.OrdinalIgnoreCase))
            .Select(ToResourcePath);

        return MergeOptions(scenes, includeValues);
    }

    private static IEnumerable<string> MergeOptions(IEnumerable<string> values, IEnumerable<string>? includeValues)
    {
        yield return "";

        foreach (var value in values.Concat(includeValues ?? []))
        {
            var cleanValue = Clean(value);
            if (cleanValue != "")
            {
                yield return cleanValue;
            }
        }
    }

    private string ToResourcePath(string path)
    {
        var relativePath = Path.GetRelativePath(projectRoot, path).Replace(Path.DirectorySeparatorChar, '/');
        return $"res://{relativePath}";
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
            SetFlagsAfterComplete = string.Join(", ", row.SetFlagsAfterComplete),
            ObjectiveText = row.ObjectiveText,
            ObjectiveRequired = row.ObjectiveRequired,
            ObjectiveCompleteFlag = row.ObjectiveCompleteFlag,
            ObjectiveBlockedMessage = row.ObjectiveBlockedMessage
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
            SetFlagsAfterComplete = ParseList(row.SetFlagsAfterComplete),
            ObjectiveText = Clean(row.ObjectiveText),
            ObjectiveRequired = row.ObjectiveRequired,
            ObjectiveCompleteFlag = Clean(row.ObjectiveCompleteFlag),
            ObjectiveBlockedMessage = Clean(row.ObjectiveBlockedMessage)
        };
    }

    private static NpcGridRow ToGridRow(NpcRow row)
    {
        return new NpcGridRow
        {
            Id = row.Id,
            DisplayName = row.DisplayName,
            DefaultTimeline = row.DefaultTimeline,
            VisibleByDefault = row.VisibleByDefault,
            Notes = row.Notes
        };
    }

    private static NpcRow FromGridRow(NpcGridRow row)
    {
        return new NpcRow
        {
            Id = Clean(row.Id),
            DisplayName = Clean(row.DisplayName),
            DefaultTimeline = Clean(row.DefaultTimeline),
            VisibleByDefault = row.VisibleByDefault,
            Notes = Clean(row.Notes)
        };
    }

    private static NpcAppearanceGridRow ToGridRow(NpcAppearanceRuleRow row)
    {
        return new NpcAppearanceGridRow
        {
            NpcId = row.NpcId,
            ScenePath = row.ScenePath,
            Days = string.Join(", ", row.Days),
            Dates = string.Join(", ", row.Dates),
            TimeBlocks = string.Join(", ", row.TimeBlocks),
            RequiredFlags = string.Join(", ", row.RequiredFlags),
            BlockedFlags = string.Join(", ", row.BlockedFlags),
            Visible = row.Visible,
            Interactable = row.Interactable
        };
    }

    private static NpcAppearanceRuleRow FromGridRow(NpcAppearanceGridRow row)
    {
        return new NpcAppearanceRuleRow
        {
            NpcId = Clean(row.NpcId),
            ScenePath = Clean(row.ScenePath),
            Days = ParseList(row.Days),
            Dates = ParseList(row.Dates),
            TimeBlocks = ParseList(row.TimeBlocks),
            RequiredFlags = ParseList(row.RequiredFlags),
            BlockedFlags = ParseList(row.BlockedFlags),
            Visible = row.Visible,
            Interactable = row.Interactable
        };
    }

    private static NpcDialogueGridRow ToGridRow(NpcDialogueRouteRow row)
    {
        return new NpcDialogueGridRow
        {
            NpcId = row.NpcId,
            Priority = row.Priority,
            Timeline = row.Timeline,
            Days = string.Join(", ", row.Days),
            Dates = string.Join(", ", row.Dates),
            TimeBlocks = string.Join(", ", row.TimeBlocks),
            RequiredFlags = string.Join(", ", row.RequiredFlags),
            BlockedFlags = string.Join(", ", row.BlockedFlags),
            SetFlagsAfterInteraction = string.Join(", ", row.SetFlagsAfterInteraction)
        };
    }

    private static NpcDialogueRouteRow FromGridRow(NpcDialogueGridRow row)
    {
        return new NpcDialogueRouteRow
        {
            NpcId = Clean(row.NpcId),
            Priority = row.Priority,
            Timeline = Clean(row.Timeline),
            Days = ParseList(row.Days),
            Dates = ParseList(row.Dates),
            TimeBlocks = ParseList(row.TimeBlocks),
            RequiredFlags = ParseList(row.RequiredFlags),
            BlockedFlags = ParseList(row.BlockedFlags),
            SetFlagsAfterInteraction = ParseList(row.SetFlagsAfterInteraction)
        };
    }

    private static List<string> ParseList(string? value)
    {
        return (value ?? "")
            .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Select(Clean)
            .Where(item => item.Length > 0)
            .ToList();
    }

    private static Dictionary<string, int> ParseStatEffects(string? value)
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
