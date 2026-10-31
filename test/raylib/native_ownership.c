// A headless raylib substitute that checks native lifetime and ABI behavior.
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include "raylib.h"

static int events[256], event_count, outstanding, fail_after = -1;
static bool drawing, clipping, scene, ready;

static void record(int event) { events[event_count++] = event; }
int TestEventCount(void) { return event_count; }
int TestEvent(int index) { return events[index]; }
int TestOutstanding(void) { return outstanding; }
int TestMeshSize(void) { return sizeof(Mesh); }
int TestModelSize(void) { return sizeof(Model); }
void TestReset(void) { event_count = 0; }
void TestFailAllocAfter(int count) { fail_after = count; }

void *MemAlloc(unsigned int size) {
    if (fail_after == 0) { fail_after = -1; return NULL; }
    if (fail_after > 0) --fail_after;
    void *p = calloc(1, size);
    if (p) ++outstanding;
    return p;
}
void MemFree(void *p) { if (p) { --outstanding; free(p); } }

void InitWindow(int width, int height, const char *title) {
    assert(width == 64 && height == 64 && title);
    ready = true;
}
bool IsWindowReady(void) { return ready; }
void CloseWindow(void) {
    assert(ready && !drawing && !scene && !clipping && outstanding == 0);
    ready = false;
    record(13);
}
void BeginDrawing(void) {
    assert(ready && !drawing);
    drawing = true;
    record(1);
}
void EndDrawing(void) {
    assert(drawing && !clipping && !scene);
    drawing = false;
    record(2);
}
void BeginScissorMode(int x, int y, int width, int height) {
    assert(drawing && !clipping && x == 0 && y == 0 && width == 32 && height == 32);
    clipping = true;
    record(3);
}
void EndScissorMode(void) { assert(clipping); clipping = false; record(4); }
void BeginMode3D(Camera3D camera) {
    assert(drawing && !scene && camera.fovy == 45);
    scene = true;
    record(5);
}
void EndMode3D(void) { assert(scene); scene = false; record(6); }
void DrawRectangle(int x, int y, int width, int height, Color color) {
    assert(drawing && !scene && width == 16 && height == 16 && color.r == 42);
    record(7);
}
void DrawBoundingBox(BoundingBox box, Color color) {
    assert(drawing && scene && box.max.x == 1 && color.r == 42);
    record(14);
}

Mesh GenMeshSphere(float radius, int rings, int slices) {
    assert(ready && radius == 1 && rings == 8 && slices == 8);
    Mesh mesh = {0};
    mesh.vertexCount = 3;
    mesh.triangleCount = 1;
    mesh.vertices = MemAlloc(9 * sizeof(float));
    mesh.vaoId = 17;
    return mesh;
}
void UploadMesh(Mesh *mesh, bool dynamic) {
    assert(ready && mesh->vertices && mesh->normals && mesh->colors && !dynamic);
    assert(mesh->vertexCount == 3 && mesh->triangleCount == 1);
    assert(mesh->vertices[0] == 1 && mesh->normals[0] == 0 && mesh->colors[0] == 42);
    mesh->vaoId = 17;
}
void UnloadMesh(Mesh mesh) {
    assert(ready);
    MemFree(mesh.vertices);
    MemFree(mesh.normals);
    MemFree(mesh.colors);
    record(10);
}
#ifndef OMIT_LOAD_MODEL
Model LoadModelFromMesh(Mesh mesh) {
    assert(mesh.vaoId == 17 && mesh.vertices);
    Model model = {0};
    model.meshCount = 1;
    model.meshes = MemAlloc(sizeof(Mesh));
    model.meshes[0] = mesh;
    model.skeleton.boneCount = 23;
    model.currentPose = (void *)0x1234;
    model.boneMatrices = (void *)0x5678;
    record(11);
    return model;
}
#endif
#ifndef OMIT_UNLOAD_MODEL
void UnloadModel(Model model) {
    assert(model.meshCount == 1 && model.meshes);
    assert(model.skeleton.boneCount == 23);
    assert(model.currentPose == (void *)0x1234 && model.boneMatrices == (void *)0x5678);
    UnloadMesh(model.meshes[0]);
    MemFree(model.meshes);
    record(12);
}
#endif
void DrawMesh(Mesh mesh, Material material, Matrix transform) {
    assert(scene && mesh.vaoId == 17 && mesh.vertices && material.maps == NULL);
    assert(transform.m0 == 1 && transform.m15 == 1);
    record(8);
}
void DrawModel(Model model, Vector3 position, float scale, Color tint) {
    assert(scene && model.meshCount == 1 && model.meshes && scale == 1 && tint.r == 42);
    record(9);
}
