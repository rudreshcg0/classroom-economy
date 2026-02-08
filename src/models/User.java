package models;

public class User {
    private int id;
    private String username;
    private String role;
    private int schoolId;
    private double balance; // Added for Phase 2 (Wallets/Allowance)

    // Standard constructor for Login
    public User(int id, String username, String role, int schoolId) {
        this.id = id;
        this.username = username;
        this.role = role;
        this.schoolId = schoolId;
    }

    // New constructor for Dashboard (includes Balance)
    public User(int id, String username, String role, int schoolId, double balance) {
        this.id = id;
        this.username = username;
        this.role = role;
        this.schoolId = schoolId;
        this.balance = balance;
    }

    // Getters
    public int getId() { return id; }
    public String getUsername() { return username; } // Added this so we can show names
    public String getRole() { return role; }
    public int getSchoolId() { return schoolId; }
    public double getBalance() { return balance; }
}