package models;

public class User {
    private int id;
    private String username;
    private String role;
    private int schoolId;
    private double balance;
    private String rollNo; // New field for Phase 2

    // Main Constructor (Full data)
    public User(int id, String username, String role, int schoolId, double balance, String rollNo) {
        this.id = id;
        this.username = username;
        this.role = role;
        this.schoolId = schoolId;
        this.balance = balance;
        this.rollNo = (rollNo == null) ? "" : rollNo; // Handle nulls for teachers
    }

    // Constructor for Login (Balance defaults to 0, RollNo to empty)
    public User(int id, String username, String role, int schoolId) {
        this(id, username, role, schoolId, 0.0, "");
    }

    // Constructor for Dashboard (Without RollNo)
    public User(int id, String username, String role, int schoolId, double balance) {
        this(id, username, role, schoolId, balance, "");
    }

    // Getters
    public int getId() { return id; }
    public String getUsername() { return username; }
    public String getRole() { return role; }
    public int getSchoolId() { return schoolId; }
    public double getBalance() { return balance; }
    public String getRollNo() { return rollNo; }
}