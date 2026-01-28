using Godot;
using System;
using System.Collections.Generic;

// Handles overall game state, shop, and pet management
public partial class GameManager : Node
{
    public static GameManager Instance;

    public List<Pet> OwnedPets = new List<Pet>();
    public Pet CurrentPet;

    // --- Shop catalog ---
    public class ShopItem
    {
        public string Name;
        public string Type; // Food, Toy, Treat, Pet
        public float Cost;
        public int EffectAmount;
    }

    public List<ShopItem> ShopItems = new List<ShopItem>()
    {
        new ShopItem() { Name="Kibble", Type="Food", Cost=2f, EffectAmount=20 },
        new ShopItem() { Name="Ball", Type="Toy", Cost=5f, EffectAmount=15 },
        new ShopItem() { Name="Treat", Type="Treat", Cost=3f, EffectAmount=10 },
        new ShopItem() { Name="New Cat", Type="Pet", Cost=20f, EffectAmount=0 },
        new ShopItem() { Name="New Dog", Type="Pet", Cost=20f, EffectAmount=0 }
    };

    public override void _Ready()
    {
        Instance = this;
    }

    // --- Buy an item from the shop ---
    public bool BuyItem(ShopItem item)
    {
        if (CurrentPet.Money >= item.Cost)
        {
            CurrentPet.Money -= item.Cost;
            CurrentPet.TotalExpenses += item.Cost;

            if (item.Type != "Pet")
            {
                if (!CurrentPet.Inventory.ContainsKey(item.Name))
                    CurrentPet.Inventory[item.Name] = 0;
                CurrentPet.Inventory[item.Name]++;
            }
            else
            {
                // Buy a new pet
                Pet newPet = new Pet()
                {
                    Species = item.Name.Contains("Dog") ? "Dog" : "Cat"
                };
                OwnedPets.Add(newPet);
            }

            // Record transaction
            CurrentPet.Ledger.Add(new Pet.Transaction
            {
                Date = DateTime.Now.ToShortDateString(),
                Category = item.Type,
                Amount = -item.Cost,
                Description = item.Name
            });
            return true;
        }
        return false;
    }
}
