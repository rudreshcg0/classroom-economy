package models;

public class User {
    private int id;
    private String username;
    private String role;
    private Integer schoolId; // Allows NULL for root
    private double balance;
    private String rollNo;

    public User(int id, String username, String role, Integer schoolId, double balance, String rollNo) {
        this.id = id;
        this.username = username;
        this.role = role;
        this.schoolId = schoolId;
        this.balance = balance;
        this.rollNo = (rollNo == null) ? "" : rollNo;
    }

    public User(int id, String username, String role, Integer schoolId) {
        this(id, username, role, schoolId, 0.0, "");
    }

    public int getId() { return id; }
    public String getUsername() { return username; }
    public String getRole() { return role; }
    public Integer getSchoolId() { return schoolId; } 
    public double getBalance() { return balance; }
    public String getRollNo() { return rollNo; }
}