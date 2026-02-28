package models;

public class User {
    private int id;
    private String username;
    private String role;
    private Integer schoolId; // Allows NULL for root
    private double balance;
    private String rollNo;
    
    // NEW: Profile Fields
    private String fullName;
    private String email;
    private String birthdate;

    // Full Constructor (Used for Login and Dashboard)
    public User(int id, String username, String role, Integer schoolId, double balance, String rollNo, String fullName, String email, String birthdate) {
        this.id = id;
        this.username = username;
        this.role = role;
        this.schoolId = schoolId;
        this.balance = balance;
        this.rollNo = (rollNo == null) ? "" : rollNo;
        this.fullName = (fullName == null) ? "" : fullName;
        this.email = (email == null) ? "" : email;
        this.birthdate = (birthdate == null) ? "" : birthdate;
    }

    // Previous Main Constructor (Updated to chain to the new Full Constructor)
    public User(int id, String username, String role, Integer schoolId, double balance, String rollNo) {
        this(id, username, role, schoolId, balance, rollNo, "", "", "");
    }

    // Previous Minimal Constructor
    public User(int id, String username, String role, Integer schoolId) {
        this(id, username, role, schoolId, 0.0, "", "", "", "");
    }

    // Existing Getters
    public int getId() { return id; }
    public String getUsername() { return username; }
    public String getRole() { return role; }
    public Integer getSchoolId() { return schoolId; } 
    public double getBalance() { return balance; }
    public String getRollNo() { return rollNo; }

    // NEW: Profile Getters
    public String getFullName() { return fullName; }
    public String getEmail() { return email; }
    public String getBirthdate() { return birthdate; }
    
    // NEW: Setters (Optional, helpful if they update profile)
    public void setFullName(String fullName) { this.fullName = fullName; }
    public void setEmail(String email) { this.email = email; }
    public void setBirthdate(String birthdate) { this.birthdate = birthdate; }
}