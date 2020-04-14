package dev.snowdrop.type;

public class Config {
    private String asciidoctorFile;
    private String roleKeyword;
    private String clusterTypeKeyword;
    private String descriptionKeywork;
    private String roleAttributeName;

    public String getRoleKeyword() {
        return roleKeyword;
    }

    public void setRoleKeyword(String roleKeyword) {
        this.roleKeyword = roleKeyword;
    }

    public String getClusterTypeKeyword() {
        return clusterTypeKeyword;
    }

    public void setClusterTypeKeyword(String clusterTypeKeyword) {
        this.clusterTypeKeyword = clusterTypeKeyword;
    }

    public String getDescriptionKeywork() {
        return descriptionKeywork;
    }

    public void setDescriptionKeywork(String descriptionKeywork) {
        this.descriptionKeywork = descriptionKeywork;
    }

    public String getRoleAttributeName() {
        return roleAttributeName;
    }

    public void setRoleAttributeName(String roleAttributeName) {
        this.roleAttributeName = roleAttributeName;
    }

    public String getAsciidoctorFile() {
        return asciidoctorFile;
    }

    public void setAsciidoctorFile(String asciidoctorFile) {
        this.asciidoctorFile = asciidoctorFile;
    }

}
