package models;

public class User {
    private int id;
    private String username;
    private String role;
    private int schoolId;

    public User(int id, String username, String role, int schoolId) {
        this.id = id;
        this.username = username;
        this.role = role;
        this.schoolId = schoolId;
    }

    // Getters
    public int getId() { return id; }
    public String getRole() { return role; }
    public int getSchoolId() { return schoolId; }
   
}