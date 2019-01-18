// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Engine/StaticMeshActor.h"
#include "CyberpunkStaticMesh.generated.h"

/**
 * 
 */
UCLASS()
class CYBERPUNK_API ACyberpunkStaticMesh : public AStaticMeshActor
{
	GENERATED_BODY()
	
public:

	UPROPERTY(EditAnywhere, AdvancedDisplay, Category = "StaticMesh")
		uint32 ListIndex;

	UPROPERTY(EditAnywhere, AdvancedDisplay, Category = "StaticMesh")
		uint32 MeshIndex;


	ACyberpunkStaticMesh();

	virtual void EditorKeyPressed(FKey key, EInputEvent Event) override;
};
