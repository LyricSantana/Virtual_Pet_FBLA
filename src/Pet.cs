using Godot;
using System;
using System.Collections.Generic;

public partial class Pet : Node2D
{
    // Core data
    public string Name { get; set; } = "BabyPet";
    public string Species { get; set; } = "Dog"; // "Dog" or "Cat"

    // Stats (0–100)
    public int Hunger { get; set; } = 50;
    public int Happiness { get; set; } = 50;
    public int Energy { get; set; } = 50;
    public int Cleanliness { get; set; } = 50;
    public int Health { get; set; } = 100;

    public int AgeDays { get; set; } = 0;
    public List<string> Badges { get; set; } = new();
    public Dictionary<string, int> Inventory { get; set; } = new() { { "Food", 0 }, { "Toy", 0 }, { "Treat", 0 } };

    // Economy
    public float Money { get; set; } = 10f;
    public float TotalExpenses { get; set; } = 0f;
    public List<Transaction> Ledger { get; set; } = new();

    // Struct for ledger
    public struct Transaction
    {
        public string Date;
        public string Category;
        public float Amount;
        public string Description;

        public Transaction(string date, string category, float amount, string desc)
        {
            Date = date;
            Category = category;
            Amount = amount;
            Description = desc;
        }
    }

    public override void _Ready()
    {
        GD.Print("Pet initialized: " + Name + " (" + Species + ")");
    }

    // ----- Actions -----
    public void Feed(string foodName, int hungerValue, float cost)
    {
        if (Inventory.ContainsKey(foodName) && Inventory[foodName] > 0)
        {
            Hunger = Math.Clamp(Hunger + hungerValue, 0, 100);
            Happiness = Math.Clamp(Happiness + 5, 0, 100);
            Inventory[foodName] -= 1;
            Money -= cost;
            TotalExpenses += cost;
            Ledger.Add(new Transaction(DateTime.Now.ToString("yyyy-MM-dd"), "Food", -cost, foodName));
            GD.Print($"{Name} ate {foodName}. Hunger: {Hunger}, Money: {Money}");
        }
        else
        {
            GD.Print("No food in inventory!");
        }
    }

    public void Play(string toyName, int happinessValue, int energyCost, float cost = 0)
    {
        if (Inventory.ContainsKey(toyName) && Inventory[toyName] > 0)
        {
            Happiness = Math.Clamp(Happiness + happinessValue, 0, 100);
            Energy = Math.Clamp(Energy - energyCost, 0, 100);
            Inventory[toyName] -= 1;
            if (cost > 0)
            {
                Money -= cost;
                TotalExpenses += cost;
                Ledger.Add(new Transaction(DateTime.Now.ToString("yyyy-MM-dd"), "Toy", -cost, toyName));
            }
            GD.Print($"{Name} played with {toyName}. Happiness: {Happiness}, Energy: {Energy}");
        }
        else
        {
            GD.Print("No toy in inventory!");
        }
    }

    public void Rest(int energyValue)
    {
        Energy = Math.Clamp(Energy + energyValue, 0, 100);
        GD.Print($"{Name} rested. Energy: {Energy}");
    }

    public void Clean(float cost = 0)
    {
        Cleanliness = 100;
        if (cost > 0)
        {
            Money -= cost;
            TotalExpenses += cost;
            Ledger.Add(new Transaction(DateTime.Now.ToString("yyyy-MM-dd"), "Cleaning", -cost, "Bath"));
        }
        GD.Print($"{Name} was cleaned. Cleanliness: {Cleanliness}");
    }

    public void Vet(float cost)
    {
        if (Money >= cost)
        {
            Health = 100;
            Money -= cost;
            TotalExpenses += cost;
            Ledger.Add(new Transaction(DateTime.Now.ToString("yyyy-MM-dd"), "Vet", -cost, "Vet visit"));
            GD.Print($"{Name} went to the vet. Health: {Health}, Money: {Money}");
        }
        else
        {
            GD.Print("Not enough money for vet!");
        }
    }

    public string HealthCheck()
    {
        if (Health < 50) return "Low health — go to vet!";
        if (Hunger < 30) return "Hungry — feed your pet!";
        if (Happiness < 30) return "Sad — play with your pet!";
        return "All stats are okay!";
    }
}
