Class {
	#name : #MiWebDCRLayerVisualizationModel,
	#superclass : #MiLayerVisualizationModel,
	#category : #'MooseIDE-NewVisu-Model'
}

{ #category : #building }
MiWebDCRLayerVisualizationModel >> buildFirstDescription [

	| sharedGroups dtos impls interfaces |
	sharedGroups := Dictionary new.
	sharedGroups at: #dto put: sharedLayer.
	sharedGroups at: #enum put: #(  ).
	dtos := self createTypeElementsFor: sharedLayer.
	impls := self createTypeElementsFor: self implementations.
	interfaces := self createTypeElementsFor: self interfaces.

	(description := MiLVVerticalBoxNode new)
		withoutBorder;
		gapSize: 90;
		add: (MiLVHorizontalBoxNode new
				 dashedBorder;
				 name: 'Shared';
				 gapSize: 80;
				 add: (MiLVFlowBoxNode new
						  dashedBorder;
						  name: 'DTOs: ' , dtos size asString , ' classes';
						  gapSize: 80;
						  addAll: (self commonPackagesFor: dtos);
						  yourself);
				 add: (MiLVFlowBoxNode new
						  dashedBorder;
						  name:
							  'Enums: ' , (sharedGroups at: #enum) size asString
							  , ' classes';
						  gapSize: 80;
						  addAll:
							  ((self commonPackagesFor: (sharedGroups at: #enum)) collect: [ 
									   :c | 
									   MiLVAbstractElement new
										   model: c;
										   yourself ]);
						  yourself);
				 yourself);
		add: (MiLVHorizontalBoxNode new
				 withoutBorder;
				 gapSize: 90;
				 add: (MiLVVerticalBoxNode new
						  dashedBorder;
						  name: 'Client';
						  addAll: (self commonPackagesFor: interfaces);
						  yourself);
				 add: (MiLVVerticalBoxNode new
						  dashedBorder;
						  name: 'Server';
						  addAll: (self commonPackagesFor: impls);
						  yourself);
				 yourself);
		add: (MiLVFlowBoxNode new
				 dashedBorder;
				 name: 'Purgatory: ' , purgatoryLayer size asString , ' classes';
				 addAll:
					 ((self commonPackagesFor: purgatoryLayer) collect: [ :c | 
							  MiLVAbstractElement new
								  model: c;
								  yourself ]);
				 yourself).
	^ description
]

{ #category : #building }
MiWebDCRLayerVisualizationModel >> commonPackagesFor: elements [

	| groups |
	groups := (elements groupedBy: [ :e | 
		           (e model atScope: FamixTPackage) anyOne ])
		          associations.

	^ groups collect: [ :a | 
		  self createPackageElement: a key with: a value ]
]

{ #category : #building }
MiWebDCRLayerVisualizationModel >> createPackageElement: famixPackage with: elements [

	^ MiLVPackageElement new
		  model: famixPackage;
		  children: elements;
		  yourself
]

{ #category : #building }
MiWebDCRLayerVisualizationModel >> createTypeElementsFor: aCollectionOfMooseEntities [

	^ aCollectionOfMooseEntities collect: [ :me | 
		  MiLVTypeElement new
			  model: me;
			  yourself ]
]

{ #category : #queries }
MiWebDCRLayerVisualizationModel >> dtos [

	^ queriesHolder DTOClasses result
]

{ #category : #queries }
MiWebDCRLayerVisualizationModel >> implementations [

	^ queriesHolder GWTServiceImplementations result
]

{ #category : #initialization }
MiWebDCRLayerVisualizationModel >> initialize [
	
	super initialize.
	queriesHolder := MiDQueriesHolder new.
]

{ #category : #partitioning }
MiWebDCRLayerVisualizationModel >> initializeFirstClientLayer [

	"Initialisation of the fist layer of clients"
	self clientLayers add: (Set withAll: self interfaces).
	
]

{ #category : #partitioning }
MiWebDCRLayerVisualizationModel >> initializeFirstServerLayer [

	self serverLayers add: (Set withAll: self implementations)
]

{ #category : #partitioning }
MiWebDCRLayerVisualizationModel >> initializePartitioning [

	
	self initializeFirstClientLayer.
	self initializeFirstServerLayer.
	self initializeSharedWithDTOs.

	continueClient := true.
	continueServer := true.
	index := 1
]

{ #category : #partitioning }
MiWebDCRLayerVisualizationModel >> initializeSharedWithDTOs [

	self sharedLayer addAll: self dtos
]

{ #category : #queries }
MiWebDCRLayerVisualizationModel >> interfaces [

	^ queriesHolder GWTServices result
]
