#version 330 compatibility
// Painted clouds replace vanilla geometry only in the Overworld.
// CLOUD_STYLE=0 disables this program and restores the loader's native fallback.
void main() {
    gl_Position = vec4(2.0, 2.0, 2.0, 1.0);
}
