{
  description = "mark";

  inputs      = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs     = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs   = import nixpkgs { inherit system; };

      writer = rec {
        bind   = m: f: let r = f m.value; in { value = r.value; write = m.write + r.write; };
        apply  = wf: wa: { value = wf.value wa.value; write = wf.write + wa.write; };
        pass   = m: { value = m.value.value; write = m.value.func m.write; };
        liftA  = f: m: { value = f m.value; write = m.write; };
        pure   = x: { value = x; write = ""; };
        listen = m: { write = m.write; value = m; };
        tell   = w: { write = w; value = null; };
        and    = m: m': bind m (_: m');
      };
    in
      with builtins;
      with pkgs.lib;
      with pkgs;
    rec {
      monad = let lift = m: _: m; in
              rec {
                bind   = m: f: r: writer.bind (m r) (a: (f a) r);
                apply  = rf: ra: r: writer.apply (rf r) (ra r);
                first  = l: r: bind l (x: and r (pure x));
                do     = o: foldl bind (pure null) o;
                listen = m: lift (writer.listen m);
                tell   = w: lift (writer.tell w);
                pass   = m: lift (writer.pass m);
                eff    = l: do (map (x: _: x) l);
                and    = m: m': bind m (_: m');
                liftA  = f: m: writer.liftA f;
                pure   = x: _: writer.pure x;
                local  = m: f: r: m (f r);
                ask    = r: writer.pure r;
                void   = m: _: m;
              };

      attrs = attr:
        let
          f = x: ''${x}=\"${attr.${x}}\"'';
          g = map f (attrNames attr);
          h = concatStringsSep " " g;
        in h;

      one   = name: attr: m:
        if length (attrNames attr) > 0
        then monad.and (monad.tell "<${name} ${attrs attr}>") m
        else monad.and (monad.tell "<${name}>") m;

      scl   = name: attr: one name attr (monad.pure null);

      tag   = name: attr: m:
        let
          f = monad.tell "</${name}>";
          g = x: monad.first (monad.and (monad.tell x) m) f;
        in
          if length (attrNames attr) > 0
          then g "<${name} ${attrs attr}>"
          else g "<${name}>";

      basic = {
        footer = tag "footer";
        header = tag "header";
        tbody  = tag "tbody";
        title  = tag "title";
        table  = tag "table";
        link   = scl "link";
        meta   = scl "meta";
        head   = tag "head";
        span   = tag "span";
        body   = tag "body";
        main   = tag "main";
        html   = tag "html";
        div    = tag "div";
        img    = tag "img";
        doc    = one "!DOCTYPE html" {};
        br     = scl "br";
        h1     = tag "h1";
        h2     = tag "h2";
        h3     = tag "h3";
        h4     = tag "h4";
        h5     = tag "h5";
        h6     = tag "h6";
        ul     = tag "ul";
        ol     = tag "ol";
        li     = tag "li";
        td     = tag "td";
        tr     = tag "tr";
        p      = tag "p";
        b      = tag "b";
        i      = tag "i";
        a      = tag "a";
      };
    };
}
