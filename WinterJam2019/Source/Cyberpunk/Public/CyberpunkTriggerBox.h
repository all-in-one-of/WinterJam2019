// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Engine/TriggerBox.h"

#include "Runtime/Engine/Classes/Components/BoxComponent.h"

#include "CyberpunkTriggerBox.generated.h"

/**
 * 
 */
UCLASS()
class CYBERPUNK_API ACyberpunkTriggerBox : public ATriggerBox
{
	GENERATED_BODY()

	friend class UBoxComponent;

private:
	
	UPROPERTY()
		UStaticMeshComponent* CubeMesh;

#if WITH_EDITOR
	//~ Begin AActor Interface.
	virtual void EditorApplyScale(const FVector& DeltaScale, const FVector* PivotLocation, bool bAltDown, bool bShiftDown, bool bCtrlDown) override;
	//~ End AActor Interface.
#endif


protected:

	virtual void OnConstruction(const FTransform& Transform) override;
		

public:

	ACyberpunkTriggerBox(); // Constructor

	UPROPERTY(EditAnywhere, AdvancedDisplay, Category = "Shape")
		UMaterialInterface* RenderMaterial;

#if WITH_EDITORONLY_DATA
	/** Returns SpriteComponent subobject **/
	UStaticMeshComponent* GetCubeMesh() const { return CubeMesh; }
#endif
};
