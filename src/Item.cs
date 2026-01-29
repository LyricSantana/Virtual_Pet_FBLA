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

    // Constructor to quickly create new items
    public Item(string name, ItemType type, float cost,
        int hunger = 0, int happiness = 0, int energy = 0, int cleanliness = 0, int health = 0)
    {

    }
}
