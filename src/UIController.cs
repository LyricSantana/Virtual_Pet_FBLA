using Godot;
using System;

// Handles UI, buttons, and updating stats
public partial class UIController : Control
{
    [Export] private NodePath PetPath;
    private Pet pet;

    public override void _Ready()
    {
        pet = GetNode<Pet>(PetPath);

        // Connect pet action buttons
        GetNode<Button>("FeedButton").Pressed += OnFeedPressed;
        GetNode<Button>("PlayButton").Pressed += OnPlayPressed;
        GetNode<Button>("RestButton").Pressed += OnRestPressed;
        GetNode<Button>("CleanButton").Pressed += OnCleanPressed;
        GetNode<Button>("VetButton").Pressed += OnVetPressed;
        GetNode<Button>("ShopButton").Pressed += OnShopPressed;

        UpdateUI();
    }

    private void OnFeedPressed()
    {
        pet.Feed("Food");
        UpdateUI();
    }

    private void OnPlayPressed()
    {
        pet.Play("Toy");
        UpdateUI();
    }

    private void OnRestPressed()
    {
        pet.Rest();
        UpdateUI();
    }

    private void OnCleanPressed()
    {
        pet.Clean();
        UpdateUI();
    }

    private void OnVetPressed()
    {
        pet.Vet();
        UpdateUI();
    }

    // --- Shop Panel toggle ---
    private void OnShopPressed()
    {
        var shopPanel = GetNode<Panel>("ShopPanel");
        shopPanel.Visible = !shopPanel.Visible;

        var tab = GetNode<TabContainer>("ShopPanel/TabContainer").CurrentTab;
        var tabName = GetNode<TabContainer>("ShopPanel/TabContainer").GetTabTitle(tab);
        var vbox = GetNode<VBoxContainer>($"ShopPanel/TabContainer/{tabName}");
        vbox.ClearChildren();

        foreach (var item in GameManager.Instance.ShopItems)
        {
            if (item.Type == tabName)
            {
                var btn = new Button() { Text = $"{item.Name} - ${item.Cost}" };
                btn.Pressed += () =>
                {
                    if (GameManager.Instance.BuyItem(item))
                        UpdateUI();
                };
                vbox.AddChild(btn);
            }
        }
    }

    private void UpdateUI()
    {
        GetNode<ProgressBar>("HungerBar").Value = pet.Hunger;
        GetNode<ProgressBar>("HappinessBar").Value = pet.Happiness;
        GetNode<ProgressBar>("EnergyBar").Value = pet.Energy;
        GetNode<ProgressBar>("CleanlinessBar").Value = pet.Cleanliness;
        GetNode<ProgressBar>("HealthBar").Value = pet.Health;
        GetNode<Label>("MoneyLabel").Text = $"Money: ${pet.Money:F2}";
    }
}
