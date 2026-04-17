package models;

public class MarketplaceItem {
    private int id;
    private String name;
    private String description;
    private double price;
    private int stock;
    private boolean requiresApproval; // Added this field

    // Updated constructor to accept 6 arguments
    public MarketplaceItem(int id, String name, String description, double price, int stock, boolean requiresApproval) {
        this.id = id;
        this.name = name;
        this.description = description;
        this.price = price;
        this.stock = stock;
        this.requiresApproval = requiresApproval;
    }

    // Getters
    public int getId() { return id; }
    public String getName() { return name; }
    public String getDescription() { return description; }
    public double getPrice() { return price; }
    public int getStock() { return stock; }
    public boolean isRequiresApproval() { return requiresApproval; } // Added getter
}