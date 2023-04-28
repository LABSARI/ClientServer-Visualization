Class {
	#name : #MiFilterViolationStrategy,
	#superclass : #MiAbstractDisplayStrategy,
	#category : #'MooseIDE-NewVisu-Strategy'
}

{ #category : #filtering }
MiFilterViolationStrategy >> fetchNotSharedDTOs [

	| shared clientLayers serverLayers incomingCache dict |
	shared := visualizationModel sharedLayer.
	clientLayers := visualizationModel clientLayers asSet flatten.
	serverLayers := visualizationModel serverLayers asSet flatten.
	incomingCache := visualizationModel incomingCache.
	dict := Dictionary new.
	dict at: #client put: OrderedCollection new.
	dict at: #server put: OrderedCollection new.
	dict at: #shared put: OrderedCollection new.
	dict at: #nothing put: OrderedCollection new.
	shared do: [ :dto | 
		incomingCache
			at: dto
			ifPresent: [ :incomings | 
				(incomings anySatisfy: [ :cc | (clientLayers like: cc) isNotNil ])
					ifTrue: [ 
						(incomings anySatisfy: [ :cc | (serverLayers like: cc) isNotNil ])
							ifTrue: [ self addDto: dto in: dict atKey: #shared ]
							ifFalse: [ self addDto: dto in: dict atKey: #client ] ]
					ifFalse: [ 
						(incomings anySatisfy: [ :cc | (serverLayers like: cc) isNotNil ]) 
							ifTrue: [ self addDto: dto in: dict atKey: #server ] ] ]
			ifAbsent: [ self addDto: dto in: dict atKey: #nothing ] ].

	^ dict
]

{ #category : #filtering }
MiFilterViolationStrategy >> fetchViolatingClients [

	| outgoingCache  violatingClient |
	outgoingCache := visualizationModel outgoingCache.

	violatingClient := OrderedCollection new.
	visualizationModel clientLayers do: [ :sl | 
		| ve |
		ve := Set new.
		visualizationModel purgatoryLayer do: [ :pc | 
			ve addAll: ((outgoingCache at: pc) intersection: sl) ].
		violatingClient add: ve ].
"	violatingClient flatten do: [ :vs | vs tagWithName: 'ClientViolation' ]."

	^ violatingClient
]

{ #category : #filtering }
MiFilterViolationStrategy >> fetchViolatingDaos [

	^ visualizationModel daoLayer select: [ :dao | 
		  dao hasTagNamed: 'daoViolation' ]
]

{ #category : #filtering }
MiFilterViolationStrategy >> fetchViolatingEntities [
	
	| incomingCache serverLayer violatingServer |
	incomingCache := visualizationModel incomingCache.
	serverLayer := visualizationModel serverLayers asSet flatten.
	violatingServer := Set new.
	
	visualizationModel purgatoryLayer do: [ :pc |  violatingServer addAll: ((incomingCache at: pc) intersection: serverLayer)].
	violatingServer do: [ :vs | vs tagWithName: 'ServerViolation'  ]
]

{ #category : #filtering }
MiFilterViolationStrategy >> fetchViolatingServers [

	| incomingCache  violatingServer |
	incomingCache := visualizationModel incomingCache.

	violatingServer := OrderedCollection new.
	visualizationModel serverLayers do: [ :sl | | ve |
		ve := Set new.
		visualizationModel purgatoryLayer do: [ :pc | 
			ve addAll: ((incomingCache at: pc) intersection: sl) ].
		violatingServer add: ve ].
"	violatingServer flatten do: [ :vs | vs tagWithName: 'ServerViolation' ]."

	^ violatingServer
]

{ #category : #filtering }
MiFilterViolationStrategy >> fetchViolatingServices [

	^ visualizationModel serviceLayer reject: [ :service | 
		  service hasTagNamed: 'serviceNoViolation' ]
]
