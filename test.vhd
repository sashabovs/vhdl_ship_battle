package DataStructures is
  type Pair is record
    x : integer;
    y : integer;
  end record;

  type Item;

  type Ptr is access Item;
  type Item is record
    Data : Pair;
    NextItem : Ptr;
  end record;

  type resArray is array(0 to 9) of Pair;
end package DataStructures;

package body DataStructures is
end package body DataStructures;