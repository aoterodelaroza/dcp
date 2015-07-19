function ac = strfields(txt)
  %% function ac = strfields(txt)
  %%
  %% Separate the string txt into a cell array of fields.
  
  ac = {};
  af = -1;
  txt = strtrim(txt);
  af = sscanf(txt,"%s","C");
  while (!isempty(af))
    ac = {ac{:} af};
    txt = strtrim(txt(length(af)+1:end));
    af = sscanf(txt,"%s","C");
  endwhile
end
