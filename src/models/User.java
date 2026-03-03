package models;

public class User {
    private int id;
    private String username;
    private String role;
    private Integer schoolId; // Allows NULL for root
    private double balance;
    private String rollNo;
    
    // Profile Fields
    private String fullName;
    private String email;
    private String birthdate;

    /**
     * Default No-Argument Constructor
     * Required for manual instantiation and certain frameworks
     */
    public User() {}

    /**
     * Full Constructor (Used for Login and Dashboard)
     */
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

    /**
     * Chained Constructor for standard user initialization
     */
    public User(int id, String username, String role, Integer schoolId, double balance, String rollNo) {
        this(id, username, role, schoolId, balance, rollNo, "", "", "");
    }

    /**
     * Minimal Constructor
     */
    public User(int id, String username, String role, Integer schoolId) {
        this(id, username, role, schoolId, 0.0, "", "", "", "");
    }

    // Getters
    public int getId() { return id; }
    public String getUsername() { return username; }
    public String getRole() { return role; }
    public Integer getSchoolId() { return schoolId; } 
    public double getBalance() { return balance; }
    public String getRollNo() { return rollNo; }
    public String getFullName() { return fullName; }
    public String getEmail() { return email; }
    public String getBirthdate() { return birthdate; }
    
    // Setters (Required for RewardServlet and Profile Updates)
    public void setId(int id) { this.id = id; }
    public void setUsername(String username) { this.username = username; }
    public void setRole(String role) { this.role = role; }
    public void setSchoolId(Integer schoolId) { this.schoolId = schoolId; }
    public void setBalance(double balance) { this.balance = balance; }
    public void setRollNo(String rollNo) { this.rollNo = rollNo; }
    public void setFullName(String fullName) { this.fullName = fullName; }
    public void setEmail(String email) { this.email = email; }
    public void setBirthdate(String birthdate) { this.birthdate = birthdate; }
}