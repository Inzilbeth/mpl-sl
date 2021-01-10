"control.&&" use
"control.@" use
"control.Natx" use
"control.Ref" use
"control.asIndexable" use
"control.assert" use
"control.dup" use
"control.each" use
"control.isAutomatic" use
"control.new" use
"control.pfunc" use
"control.set" use
"control.when" use
"control.while" use
"memory.mplFree" use
"memory.mplRealloc" use

makeArrayRangeRaw: [{
  virtual RANGE: ();
  virtual ARRAY_RANGE: ();
  dataBegin:;
  dataSize: new;
  virtual elementType: @dataBegin Ref;
  virtual elementSize: @dataBegin storageSize;
  @dataBegin storageAddress @elementType addressToReference !dataBegin #dynamize

  getBufferBegin: [
    @dataBegin storageAddress
  ];

  at: [
    index:;
    index 0i32 same ~ [0 .ONLY_I32_ALLOWED] when
    [index 0 < ~ [index dataSize <] &&] "Index is out of range!" assert
    getBufferBegin index Natx cast elementSize * + @elementType addressToReference
  ];

  size: [
    dataSize
  ];

  view: [
    newIndex: newSize:;;
    {
      virtual elementType: @elementType Ref;
      getBufferBegin: getBufferBegin elementType storageSize newIndex Natx cast * +;
      size: newSize new;

      at: [Natx cast elementType storageSize * getBufferBegin + @elementType addressToReference];

      view: @view;
    }
  ];

  getSize: [
    dataSize new
  ];

  heapSortWithComparator: [
    comparator:;

    swap: [
      i1:; i2:;
      i1ref: i1 at;
      i2ref: i2 at;
      tmp: @i1ref dup isAutomatic ~ [const] when new;
      @i2ref dup isAutomatic ~ [const] when @i1ref set
      @tmp dup isAutomatic ~ [const] when @i2ref set
    ];

    pushDown: [
      index: new;
      [
        left: index 2 * 1 +;
        right: left 1 +;

        max: index new;
        left  heapSize < [max at left  at @comparator call] && [left  @max set] when
        right heapSize < [max at right at @comparator call] && [right @max set] when
        max index = ~ [
          max index swap
          max @index set TRUE
        ] &&
      ] loop
    ];

    heapSize: dataSize new;
    i: dataSize 1 + 2 /;
    [i 0 >] [
      i 1 - @i set
      i pushDown
    ] while

    i: dataSize new;
    [i 1 >] [
      i 1 - @i set
      i 0 swap
      heapSize 1 - @heapSize set
      0 dynamic pushDown
    ] while
  ];

  heapSort: [
    [<] heapSortWithComparator
  ];
}];

ArrayRange: [
  element:;
  0 @element Ref makeArrayRangeRaw
];

makeArrayRange: [
  list:;
  virtual listSchema: @list Ref;
  virtual elementSchema: 0 dynamic @listSchema @ Ref;
  list fieldCount 0 dynamic list @ storageAddress @elementSchema addressToReference makeArrayRangeRaw
];

makeArrayRange: ["ARRAY_RANGE" has] [
  new
] pfunc;

makeArrayRange: ["ARRAY" has] [
  .getArrayRange
] pfunc;

makeSubRange: [
  makeArrayRange arg:;
  rangeEndIndex:;
  rangeBeginIndex:;
  [0 rangeBeginIndex > ~] "Invalid subrange, 0>begin!" assert
  [rangeBeginIndex rangeEndIndex > ~] "Invalid subrange, begin>end!" assert
  [rangeEndIndex arg.dataSize > ~] "Invalid subrange, end>size!" assert
  rangeEndIndex rangeBeginIndex - arg.getBufferBegin arg.elementSize rangeBeginIndex Natx cast * + @arg.@elementType addressToReference makeArrayRangeRaw
];

makeArrayObject: [{
  virtual memoryDebugObject: new;

  virtual CONTAINER: ();
  virtual ARRAY: ();
  virtual SCHEMA_NAME: "Array";
  virtual elementType: Ref;
  dataBegin: @elementType Ref;
  dataSize: 0;
  dataReserve: 0;
  virtual elementSize: @elementType storageSize;

  getBufferBegin: [
    @dataBegin storageAddress
  ];

  at: [
    index:;
    index 0i32 same ~ [0 .ONLY_I32_ALLOWED] when
    [index 0 < ~ [index dataSize <] &&] "Index is out of range!" assert
    getBufferBegin index Natx cast elementSize * + @elementType addressToReference
  ];

  size: [
    dataSize new
  ];

  view: [
    newIndex: newSize:;;
    {
      virtual SCHEMA_NAME: "ArrayView";
      virtual elementType: @elementType Ref;
      dataBegin: @dataBegin storageAddress @elementType storageSize newIndex Natx cast * + @elementType addressToReference;
      size: newSize new;

      at: [Natx cast @elementType storageSize * @dataBegin storageAddress + @elementType addressToReference];

      view: @view;
    }
  ];

  erase: [
    index:;
    index 0i32 same ~ [0 .ONLY_I32_ALLOWED] when
    [index 0 < ~ [index dataSize <] &&] "Index is out of range!" assert

    index getSize 1 - < [
      last dup isAutomatic ~ [const] when index at set
    ] when

    popBack
  ];

  eraseIf: [
    eraseIfBody:;
    index: 0;
    self toIter @eraseIfBody filterIter [
      index at set
      index 1 + !index
    ] each

    index shrink
  ];

  getSize: [dataSize new];

  getArrayRange: [
    dataSize @dataBegin storageAddress @elementType addressToReference makeArrayRangeRaw
  ];

  getNextReserve: [
    dataReserve dataReserve 4 / + 4 +
  ];

  setReserve: [
    newReserve:;
    [newReserve dataReserve < ~] "New reserve is less than old reserve!" assert
    memoryDebugObject [TRUE !memoryDebugEnabled] when
    newReserve Natx cast elementSize * dataReserve Natx cast elementSize * getBufferBegin mplRealloc
    memoryDebugObject [FALSE !memoryDebugEnabled] when
    @elementType addressToReference !dataBegin
    newReserve @dataReserve set
  ];

  addReserve: [
    dataSize dataReserve = [
      getNextReserve setReserve
    ] when
  ];

  pushBack: [
    element:;
    addReserve
    dataSize 1 + @dataSize set
    newElement: dataSize 1 - at;
    @newElement manuallyInitVariable
    @element @newElement set
  ];

  appendAll: [
    view: asIndexable;
    index: size;
    size view.size + enlarge
    i: 0; [i view.size <] [
      i view.at index i + at set i 1 + !i
    ] while
  ];

  appendEach: [[pushBack] each];

  shrink: [
    newSize:;
    [newSize dataSize > ~] "Shrinked size is bigger than the old size!" assert

    i: dataSize new;
    [i newSize >] [
      i 1 - @i set
      i at manuallyDestroyVariable
    ] while
    newSize @dataSize set
  ];

  popBack: [
    [dataSize 0 >] "Pop from empty array!" assert
    dataSize 1 - shrink
  ];

  last: [
    dataSize 1 - at
  ];

  enlarge: [
    newSize: dynamic;
    [newSize dataSize < ~] "Enlarged size is less than old size!" assert

    dataReserve newSize < [
      newReserve: getNextReserve;
      newReserve newSize < [newSize @newReserve set] when
      newReserve setReserve
    ] when

    i: dataSize new;
    newSize @dataSize set
    [i dataSize <] [
      i at manuallyInitVariable
      i 1 + @i set
    ] while
  ];

  resize: [
    newSize:;
    newSize dataSize = [
    ] [
      newSize dataSize < [
        newSize shrink
      ] [
        newSize enlarge
      ] if
    ] if
  ];

  clear: [
    0 shrink
  ];

  release: [
    clear
    addr: getBufferBegin;
    size: dataReserve Natx cast elementSize *;
    memoryDebugObject [TRUE !memoryDebugEnabled] when
    addr 0nx = ~ [size addr mplFree] when
    memoryDebugObject [FALSE !memoryDebugEnabled] when
    @elementType Ref !dataBegin
    0 @dataSize set
    0 @dataReserve set
  ];

  INIT: [
    @elementType Ref !dataBegin
    0 @dataSize set
    0 @dataReserve set
  ];

  ASSIGN: [
    other:;
    other.dataSize resize

    i: 0 dynamic;
    [i dataSize <] [
      i other.at i at set
      i 1 + @i set
    ] while
  ];

  DIE: [
    clear
    addr: getBufferBegin;
    size: dataReserve Natx cast elementSize *;
    memoryDebugObject [TRUE !memoryDebugEnabled] when
    addr 0nx = ~ [size addr mplFree] when
    memoryDebugObject [FALSE !memoryDebugEnabled] when
  ];
}];

Array: [FALSE makeArrayObject];
MemoryDebugArray: [TRUE makeArrayObject];

makeArray: [
  indexable: asIndexable;
  [indexable.size 0 >] "List is empty!" assert
  result: 0 @indexable @ newVarOfTheSameType Array;
  i: 0 dynamic;
  [
    i indexable.size < [
      i @indexable @ @result.pushBack
      i 1 + @i set TRUE
    ] &&
  ] loop

  @result
];

getHeapUsedSize: ["ARRAY" has] [
  arg:;
  result: arg.elementType storageSize arg.dataReserve Natx cast *;
  i: 0 dynamic;
  [
    i arg.getSize < [
      result i arg.at getHeapUsedSize + @result set
      i 1 + @i set TRUE
    ] &&
  ] loop

  result
] pfunc;
