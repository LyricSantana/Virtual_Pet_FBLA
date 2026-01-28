using Godot;
using System.Text.Json;

public static partial class SaveLoad
{
    private static string SavePath => "user://pet_save.json";

    public static void Save(Pet pet)
    {
        var json = JsonSerializer.Serialize(pet, new JsonSerializerOptions { WriteIndented = true });
        var file = new File();
        file.Open(SavePath, File.ModeFlags.Write);
        file.StoreString(json);
        file.Close();
    }

    public static Pet Load()
    {
        var file = new File();
        if (!file.FileExists(SavePath)) return null;

        file.Open(SavePath, File.ModeFlags.Read);
        var json = file.GetAsText();
        file.Close();
        return JsonSerializer.Deserialize<Pet>(json);
    }
}
