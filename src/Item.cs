using System;


// Enum representing different types of items in the shop.
// Used to categorize effects and spending.

public enum ItemType
{
    Food,
    Toy,
    Clean,
    Vet
}


// Represents a single purchasable item in the shop.
// Each item knows its cost and stat effects.

public class Item
{
    public string Name;         // Display name
    public ItemType Type;       // Type of item
    public float Cost;          // Money required
    public int HungerEffect;    // Stat changes when used
    public int HappinessEffect;
    public int EnergyEffect;
    public int CleanlinessEffect;
    public int HealthEffect;

    // Constructor to quickly create new items
    public Item(string name, ItemType type, float cost,
        int hunger = 0, int happiness = 0, int energy = 0, int cleanliness = 0, int health = 0)
    {
        Name = name;
        Type = type;
        Cost = cost;
        HungerEffect = hunger;
        HappinessEffect = happiness;
        EnergyEffect = energy;
        CleanlinessEffect = cleanliness;
        HealthEffect = health;
    }
}
