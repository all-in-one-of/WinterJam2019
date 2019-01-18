// Fill out your copyright notice in the Description page of Project Settings.

#include "CyberpunkStaticMesh.h"

ACyberpunkStaticMesh::ACyberpunkStaticMesh()
{
	

	//AStaticMeshActor::AStaticMeshActor(); // Call parent constructor
}

void ACyberpunkStaticMesh::EditorKeyPressed(FKey Key, EInputEvent Event)
{


	AActor::EditorKeyPressed(Key, Event);
}