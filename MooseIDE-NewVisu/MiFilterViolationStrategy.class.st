Class {
	#name : #MiFilterViolationStrategy,
	#superclass : #MiLayerDisplayStrategy,
	#category : #'MooseIDE-NewVisu-Strategy'
}

{ #category : #filtering }
MiFilterViolationStrategy >> fetchNotSharedDTOs [

	| shared clientLayers serverLayers incomingCache dict clientProviders serverProviders |
	shared := visualizationModel sharedLayer.
	clientLayers := visualizationModel clientLayers asSet flatten.
	serverLayers := visualizationModel serverLayers asSet flatten.
	incomingCache := visualizationModel incomingCache.
	dict := Dictionary new.
	dict at: #client put: OrderedCollection new.
	dict at: #server put: OrderedCollection new.
	dict at: #shared put: OrderedCollection new.
	dict at: #nothing put: OrderedCollection new.
	clientProviders := clientLayers flatCollectAsSet: #allProviders.
	serverProviders := serverLayers flatCollectAsSet: #allProviders.
	shared do: [ :dto | 
		(clientProviders like: dto)
			ifNotNil: [ 
				(serverProviders like: dto)
					ifNotNil: [ self addDto: dto in: dict atKey: #shared ]
					ifNil: [ self addDto: dto in: dict atKey: #client ] ]
			ifNil: [ 
				(serverProviders like: dto)
					ifNotNil: [ self addDto: dto in: dict atKey: #server ]
					ifNil: [ self addDto: dto in: dict atKey: #nothing ] ] ].

	"
		
		
		self haltIf: [ 	((clientLayers flatCollectAsSet: #allProviders ) like: dto) isNotNil  ] .
		incomingCache
			at: dto
			ifPresent: [ :incomings | 
				(incomings anySatisfy: [ :cc | (serverLayers like: cc) isNotNil ])
					ifTrue: [ 
						(incomings anySatisfy: [ :cc | (serverLayers like: cc) isNotNil ])
							ifTrue: [ self addDto: dto in: dict atKey: #shared ]
							ifFalse: [ self addDto: dto in: dict atKey: #client ] ]
					ifFalse: [ 
						(incomings anySatisfy: [ :cc | (serverLayers like: cc) isNotNil ]) 
							ifTrue: [ self addDto: dto in: dict atKey: #server ] ] ]
			ifAbsent: [ self addDto: dto in: dict atKey: #nothing ] ]."

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
MiFilterViolationStrategy >> shouldDisplaySharedDTOs [

	^ false
]
